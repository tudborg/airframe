defmodule Airframe.Resource do
  @moduledoc """
  Query module for Airframe, wrapping Ecto.Query and Repo functions to check and annotate authentication.
  """

  @doc """
  Scope a queryable to the provided context.
  """
  @callback scope(queryable :: Ecto.Queryable.t(), context :: any(), scope :: any()) ::
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
  def scope(queryable, context, scope) do
    case Ecto.Queryable.to_query(queryable) do
      %Ecto.Query{from: %{source: {_source, schema}}} when not is_nil(schema) ->
        queryable = schema.scope(queryable, context, scope)

        if is_nil(Ecto.Queryable.impl_for(queryable)) do
          raise ArgumentError,
                "#{inspect(schema)}.scope/3 must return a value that implements the Ecto.Queryable protocol." <>
                  "\nBut scope #{inspect(scope)} returned #{inspect(queryable)}"
        else
          queryable
        end
    end
  end
end
