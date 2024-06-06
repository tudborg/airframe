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
  def scope(queryable, context, opts) do
    case Ecto.Queryable.to_query(queryable) do
      %Ecto.Query{from: %{source: {_source, schema}}} when not is_nil(schema) ->
        case schema.scope(queryable, context, opts) do
          %Ecto.Query{} = query -> query
        end
    end
  end
end
