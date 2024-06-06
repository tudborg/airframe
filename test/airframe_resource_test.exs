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
    assert %Ecto.Query{} = query = Airframe.Resource.scope(MySchema, {:user, 1}, [])
    assert [%Ecto.Query.BooleanExpr{} = expr] = query.wheres
    assert expr.op == :and
    assert expr.expr == {:==, [], [{{:., [], [{:&, [], [0]}, :user_id]}, [], []}, {:^, [], [0]}]}
    assert expr.params == [{1, {0, :user_id}}]
  end

  describe "tag/2" do
    test "tags a struct with the context" do
      struct = %MySchema{}
      assert Airframe.Resource.context(struct) == nil
      struct = Airframe.Resource.tag(struct, {:user, 1})
      assert Airframe.Resource.context(struct) == {:user, 1}
      struct = Airframe.Resource.tag(struct, nil)
      assert Airframe.Resource.context(struct) == nil
    end

    test "tags a list of structs" do
      context = {:user, 1}

      assert [context, context] ==
               [%MySchema{}, %MySchema{}]
               |> Airframe.Resource.tag(context)
               |> Enum.map(&Airframe.Resource.context/1)
    end

    test "tags an {:ok, _} tuple" do
      context = {:user, 1}

      # a single item in an OK tuple
      assert {:ok, %MySchema{__meta__: %{context: ^context}}} =
               {:ok, %MySchema{}}
               |> Airframe.Resource.tag(context)

      # a list of items in an OK tuple
      assert {:ok, [%MySchema{__meta__: %{context: ^context}}]} =
               {:ok, [%MySchema{}]}
               |> Airframe.Resource.tag(context)

      # an empty list in an OK tuple
      assert {:ok, []} =
               {:ok, []}
               |> Airframe.Resource.tag(context)
    end

    test "passes through {:error, _} tuple" do
      assert {:error, :oops} == Airframe.Resource.tag({:error, :oops}, {:user, 1})
    end
  end

  describe "check!/2" do
    setup do
      %{tagged: Airframe.Resource.tag(%MySchema{}, {:user, 1})}
    end

    test "passes through the schema when contexts are identical", ctx do
      assert ctx.tagged == Airframe.Resource.check!(ctx.tagged, {:user, 1})
    end

    test "rasies when a nil subject is provided", _ctx do
      assert_raise Airframe.CheckError, fn ->
        Airframe.Resource.check!(nil, {:user, 1})
      end
    end

    test "raises an error when the context is nil", ctx do
      assert_raise Airframe.CheckError, fn ->
        Airframe.Resource.check!(ctx.tagged, nil)
      end
    end

    test "raises an error when the context is not compatible", ctx do
      assert_raise Airframe.CheckError, fn ->
        Airframe.Resource.check!(ctx.tagged, {:user, 2})
      end
    end
  end

  describe "compatible?/2" do
    defmodule User do
      use Ecto.Schema

      schema "users" do
        field(:name, :string)
      end
    end

    test "returns true when the contexts are identical" do
      assert Airframe.Resource.compatible?({:user, 1}, {:user, 1})
    end

    test "returns false when the contexts are different" do
      refute Airframe.Resource.compatible?({:user, 1}, {:user, 2})
    end

    test "compares only primary keys when both are Ecto Schemas" do
      ctx_a = %User{id: 1, name: "a"}
      ctx_also_a = %User{id: 1, name: "also_a"}
      ctx_b = %User{id: 2, name: "b"}

      # identical, so compatible:
      assert Airframe.Resource.compatible?(ctx_a, ctx_a)
      # same primary keys, so compatible:
      assert Airframe.Resource.compatible?(ctx_a, ctx_also_a)
      # different primary key, so not compatible:
      refute Airframe.Resource.compatible?(ctx_a, ctx_b)
      # when one is not an Ecto.Schema, never compare primary keys:
      refute Airframe.Resource.compatible?({:user, 1}, ctx_b)
      refute Airframe.Resource.compatible?(ctx_a, {:user, 2})
    end
  end
end
