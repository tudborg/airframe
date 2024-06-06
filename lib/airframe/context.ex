defmodule Airframe.Context do
  @moduledoc false

  @doc """
  Check if the `subject` context is "the same" as the `trusted` context.
  """
  def same?(subject, trusted)

  def same?(trusted, trusted) do
    true
  end

  def same?(
        %{__meta__: %Ecto.Schema.Metadata{}} = subject,
        %{__meta__: %Ecto.Schema.Metadata{}} = trusted
      ) do
    # find the columns of the primary key for both contexts:
    subject_primary_key_cols = subject.__meta__.schema.__schema__(:primary_key)
    trusted_primary_key_cols = trusted.__meta__.schema.__schema__(:primary_key)
    # take the actual values from the structs:
    subject_primary_key = Map.take(subject, subject_primary_key_cols)
    trusted_primary_key = Map.take(trusted, trusted_primary_key_cols)
    # compare the primary keys:
    subject_primary_key == trusted_primary_key
  end

  def same?(_subject, _trusted) do
    false
  end

  @doc """
  Tag Ecto Schema tuples with authentication context.

  This allows functions later down the pipeline to validate
  that the given struct was loaded with the correct context,
  and allow implicit loading of related data like associations
  with the same security scope.
  """
  def tag(subject, context)

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

  def context(%{__meta__: %Ecto.Schema.Metadata{context: context}}), do: {:ok, context}
  def context(_), do: {:error, :no_context}

  def context!(thing) do
    case context(thing) do
      {:ok, context} -> context
      {:error, _} -> raise ArgumentError, "no context found for #{inspect(thing)}"
    end
  end
end
