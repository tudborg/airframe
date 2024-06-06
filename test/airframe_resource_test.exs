defmodule AirframeResourceTest do
  use Airframe.Case, async: true
  import Ecto.Query
  doctest Airframe.Resource

  defmodule MySchema do
    use Ecto.Schema
    use Airframe.Resource

    import Ecto.Query

    schema "things" do
      field(:user_id, :integer)
    end

    def scope(queryable, {:user, user_id}, _opts) do
      where(queryable, [t], t.user_id == ^user_id)
    end
  end

  test "scope/3 scopes the Queryable and returns an %Ecto.Query{}" do
    assert %Ecto.Query{} = query = Airframe.scope(MySchema, {:user, 1})
    assert %Ecto.Query{} = ^query = Airframe.scope(MySchema, {:user, 1}, [])
    assert [%Ecto.Query.BooleanExpr{} = expr] = query.wheres
    assert expr.op == :and
    assert expr.expr == {:==, [], [{{:., [], [{:&, [], [0]}, :user_id]}, [], []}, {:^, [], [0]}]}
    assert expr.params == [{1, {0, :user_id}}]
  end
end
