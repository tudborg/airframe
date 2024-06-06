defmodule AirframeContextTest do
  use Airframe.Case, async: true
  doctest Airframe.Context

  defmodule MySchema do
    use Ecto.Schema

    schema "things" do
      field(:user_id, :integer)
    end
  end

  describe "tag/2" do
    test "tags a struct with the context" do
      struct = %MySchema{}
      assert Airframe.context!(struct) == nil
      struct = Airframe.tag(struct, {:user, 1})
      assert Airframe.context!(struct) == {:user, 1}
      struct = Airframe.tag(struct, nil)
      assert Airframe.context!(struct) == nil
    end

    test "tags a list of structs" do
      context = {:user, 1}

      assert [context, context] ==
               [%MySchema{}, %MySchema{}]
               |> Airframe.tag(context)
               |> Enum.map(&Airframe.context!/1)
    end

    test "tags nil just returns nil" do
      assert nil == Airframe.tag(nil, {:user, 1})
    end

    test "tags an {:ok, _} tuple" do
      context = {:user, 1}

      # a single item in an OK tuple
      assert {:ok, %MySchema{__meta__: %{context: ^context}}} =
               {:ok, %MySchema{}}
               |> Airframe.tag(context)

      # a list of items in an OK tuple
      assert {:ok, [%MySchema{__meta__: %{context: ^context}}]} =
               {:ok, [%MySchema{}]}
               |> Airframe.tag(context)

      # an empty list in an OK tuple
      assert {:ok, []} =
               {:ok, []}
               |> Airframe.tag(context)
    end

    test "passes through {:error, _} tuple" do
      assert {:error, :oops} == Airframe.tag({:error, :oops}, {:user, 1})
    end
  end

  describe "same?/2" do
    defmodule User do
      use Ecto.Schema

      schema "users" do
        field(:name, :string)
      end
    end

    test "returns true when the contexts are identical" do
      assert Airframe.same?({:user, 1}, {:user, 1})
    end

    test "returns false when the contexts are different" do
      refute Airframe.same?({:user, 1}, {:user, 2})
    end

    test "compares only primary keys when both are Ecto Schemas" do
      ctx_a = %User{id: 1, name: "a"}
      ctx_also_a = %User{id: 1, name: "also_a"}
      ctx_b = %User{id: 2, name: "b"}

      # identical, so compatible:
      assert Airframe.same?(ctx_a, ctx_a)
      # same primary keys, so compatible:
      assert Airframe.same?(ctx_a, ctx_also_a)
      # different primary key, so not compatible:
      refute Airframe.same?(ctx_a, ctx_b)
      # when one is not an Ecto.Schema, never compare primary keys:
      refute Airframe.same?({:user, 1}, ctx_b)
      refute Airframe.same?(ctx_a, {:user, 2})
    end
  end

  describe "context/1 and context!/1" do
    test "returns the context from a struct" do
      struct = %MySchema{}
      assert Airframe.context(struct) == {:ok, nil}
      assert Airframe.context!(struct) == nil
      struct = Airframe.tag(struct, {:user, 1})
      assert Airframe.context!(struct) == {:user, 1}
    end

    test "context!/1 raises when subject cannot have a context" do
      assert_raise ArgumentError, fn ->
        Airframe.context!(:dummy)
      end
    end
  end
end
