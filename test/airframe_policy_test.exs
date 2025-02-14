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
      def allow(:very, :specific, :values), do: true
    end

    test "default false policy always rejects" do
      assert {:error, {:unauthorized, _}} =
               Airframe.check(:write, :my_subject, :me, DefaultFalsePolicy)
    end

    test "default true policy returns true" do
      assert {:ok, :my_subject} = Airframe.check(:write, :my_subject, :me, DefaultTruePolicy)
    end

    test "no default and no allow/3 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn ->
        Airframe.check(:write, :my_subject, :me, NoDefaultPolicy)
      end
    end
  end

  defmodule AllowPolicy do
    use Airframe.Policy
    def allow(_, _, _), do: true
  end

  test "implementing (_,_,_) -> true always allows" do
    assert {:ok, :my_subject} = Airframe.check(:write, :my_subject, :me, AllowPolicy)
  end

  defmodule AdminPolicy do
    use Airframe.Policy, default: false
    def allow(_, _, :admin), do: true
  end

  test "allows admin in admin policy" do
    assert {:ok, :my_subject} = Airframe.check(:write, :my_subject, :admin, AdminPolicy)
  end

  test "refuses me in admin policy" do
    assert {:error, {:unauthorized, _}} =
             Airframe.check(:write, :my_subject, :me, AdminPolicy)
  end

  defmodule ScopingPolicy do
    use Airframe.Policy
    def allow(:read, :my_subject, :me), do: {:ok, :my_scoped_subject}
  end

  test "allow scopes the subject" do
    assert {:ok, :my_scoped_subject} =
             Airframe.check(:read, :my_subject, :me, ScopingPolicy)
  end
end
