defmodule Airframe.Resource do
  @moduledoc """
  Query module for Airframe, wrapping Ecto.Query and Repo functions to check and annotate authentication.
  """

  @doc """
  Scope a queryable to the provided context.
  """
  @callback scope(queryable :: Ecto.Queryable.t(), context :: any(), opts :: Keyword.t()) ::
              Ecto.Queryable.t()

  @doc """
  Declare that the module is a Resource.
  It should also be an `Ecto.Schema`.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Airframe.Resource
    end
  end

  @doc """
  Scope a queryable to the provided context.

  Calls the Schema's scope/3` function.
  """
  def scope(queryable, context, opts \\ []) do
    case Ecto.Queryable.to_query(queryable) do
      %Ecto.Query{from: %{source: {_source, schema}}} when not is_nil(schema) ->
        case schema.scope(queryable, context, opts) do
          %Ecto.Query{} = query -> query
        end
    end
  end

  ## TODO: Should we have a `preload`  function that scopes the preloadable
  ## associations such that we only allow loading context scoped data automatically?

  @doc """
  Tag Ecto Schema tuples with authentication context.

  This allows functions later down the pipeline to validate
  that the given struct was loaded with the correct context,
  and allow implicit loading of related data like associations
  with the same security scope.
  """
  def tag(nil, _context) do
    nil
  end

  def tag({:error, _} = error, _context) do
    error
  end

  # tag inside an OK tuple
  def tag({:ok, result}, context) do
    {:ok, tag(result, context)}
  end

  # tag a single result
  def tag(%{__meta__: %Ecto.Schema.Metadata{}} = result, context) do
    case tag([result], context) do
      [tagged] -> tagged
    end
  end

  # the actual tagging function of a collection of ecto schema structs:
  def tag([], _context) do
    []
  end

  def tag([%{__meta__: %Ecto.Schema.Metadata{}} | _] = results, context)
      when is_list(results) do
    Enum.map(results, fn result ->
      # update the __meta__ key, putting the context in the context key.
      Map.update!(result, :__meta__, &Map.put(&1, :context, context))
    end)
  end

  @doc """
  Retrieve the context from the ecto schema struct.
  """
  def context(%{__meta__: %{context: context}}), do: context

  def context(thing),
    do: raise(ArgumentError, "argument must be an Ecto.Schema struct, got: #{inspect(thing)}")

  @doc """
  Validate that the authentication context of a struct is compatible with the provided context.

  This presumes a previous call to `tag` has been made to annotate the struct with the context
  that loaded the struct.
  """
  def check!(_, nil) do
    raise Airframe.CheckError, message: "You must provide a non-nil context to check against"
  end

  def check!(nil, _) do
    raise Airframe.CheckError, message: "You must provide a non-nil struct to check against"
  end

  def check!(struct, context) when is_struct(struct) do
    case check!([struct], context) do
      [checked] -> checked
    end
  end

  def check!(structs, context) when is_list(structs) do
    Enum.map(structs, &check_single!(&1, context))
  end

  defp check_single!(nil, _context) do
    nil
  end

  defp check_single!(%_{__meta__: %Ecto.Schema.Metadata{}} = struct, context) do
    if compatible?(context(struct), context) do
      struct
    else
      raise Airframe.CheckError,
        message: "struct loaded with incompatible authentication context"
    end
  end

  @doc """
  Check if two contexts are compatible.

  The first argument is the context under investigation, and the second is the source of truth context.
  I.e. the first context argument is the context that was used to load the struct,
  and the second context argument is the context of the current authentication.

  The first context argument must therefore conform to what is permissible by the second context argument.

  Currently, the two contexts are compatible if they are identical,
  or if they are both Ecto.Schema structs, and have the same primary key values.
  """
  def compatible?(context_under_investigation, source_of_truth_context)

  def compatible?(context, context) do
    true
  end

  def compatible?(
        %{__meta__: %Ecto.Schema.Metadata{}} = investigate,
        %{__meta__: %Ecto.Schema.Metadata{}} = trust
      ) do
    # find the columns of the primary key for both contexts:
    investigate_primary_key_cols = investigate.__meta__.schema.__schema__(:primary_key)
    trust_primary_key_cols = trust.__meta__.schema.__schema__(:primary_key)
    # take the actual values from the structs:
    investigate_primary_key = Map.take(investigate, investigate_primary_key_cols)
    trust_primary_key = Map.take(trust, trust_primary_key_cols)
    # compare the primary keys:
    investigate_primary_key == trust_primary_key
  end

  # TODO: we could also delegate to the schema module of the source_of_truth_context
  # to check if it is compatible with the context_under_investigation.
  # Maybe this is necesary if the user contains a `role` that could have changed
  # between the two checks? Is primary key checking even a good enough default?

  def compatible?(_struct, _context), do: false
end
