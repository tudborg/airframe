defmodule AirframePolicyTest do
  use Airframe.Case, async: true
  doctest Airframe.Policy

  describe "default" do
    defmodule DefaultFalsePolicy do
      use Airframe.Policy, default: false
    end

    defmodule DefaultTruePolicy do
      use Airframe.Policy, default: true
    end

    defmodule NoDefaultPolicy do
      use Airframe.Policy
      def allow?(:very, :specific, :values), do: true
    end

    test "default false policy always rejects" do
      refute Airframe.allow?(DefaultFalsePolicy, :me, :write, %{})
    end

    test "default true policy returns true" do
      assert Airframe.allow?(DefaultTruePolicy, :me, :write, %{})
    end

    test "no default and no allow?/3 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn ->
        Airframe.allow?(NoDefaultPolicy, :me, :write, %{})
      end
    end
  end

  defmodule AllowPolicy do
    use Airframe.Policy
    def allow?(_, _, _), do: true
  end

  test "implementing (_,_,_) -> true always allows" do
    assert Airframe.allow?(AllowPolicy, :me, :write, %{})
  end

  defmodule AdminPolicy do
    use Airframe.Policy, default: false
    def allow?(:admin, _, _), do: true
  end

  test "allows admin in admin policy" do
    assert Airframe.allow?(AdminPolicy, :admin, :write, %{})
  end

  test "refuses me in admin policy" do
    refute Airframe.allow?(AdminPolicy, :me, :write, %{})
  end
end
