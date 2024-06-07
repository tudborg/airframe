defmodule Airframe.Resource do
  @moduledoc """
  A behaviour to extend Ecto.Schema modules with query scoping conventions.

  This module is intended to be used with `use Airframe.Resource` in your schema modules,
  and serves mostly to document your intention of implementing the `scope/2` function.
  """

  @doc """
  Scope a queryable to the provided context.
  """
  @callback scope(queryable :: Ecto.Queryable.t(), scope :: any()) ::
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
  Scope a queryable, typically to a user's permissions, but can be any scoping rules.

  Calls the Schema's scope/2` function.

  ## Example

      Airframe.Resource.scope(query, my_user_struct)
  """
  def scope(queryable, scope) do
    case Ecto.Queryable.to_query(queryable) do
      %Ecto.Query{from: %{source: {_source, schema}}} when not is_nil(schema) ->
        queryable = schema.scope(queryable, scope)

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
