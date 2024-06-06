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
               Airframe.allowed(:my_subject, :me, :write, DefaultFalsePolicy)
    end

    test "default true policy returns true" do
      assert {:ok, :my_subject} = Airframe.allowed(:my_subject, :me, :write, DefaultTruePolicy)
    end

    test "no default and no allow/3 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn ->
        Airframe.allowed(:my_subject, :me, :write, NoDefaultPolicy)
      end
    end
  end

  defmodule AllowPolicy do
    use Airframe.Policy
    def allow(_, _, _), do: true
  end

  test "implementing (_,_,_) -> true always allows" do
    assert {:ok, :my_subject} = Airframe.allowed(:my_subject, :me, :write, AllowPolicy)
  end

  defmodule AdminPolicy do
    use Airframe.Policy, default: false
    def allow(_, :admin, _), do: true
  end

  test "allows admin in admin policy" do
    assert {:ok, :my_subject} = Airframe.allowed(:my_subject, :admin, :write, AdminPolicy)
  end

  test "refuses me in admin policy" do
    assert {:error, {:unauthorized, _}} =
             Airframe.allowed(:my_subject, :me, :write, AdminPolicy)
  end

  defmodule ScopingPolicy do
    use Airframe.Policy
    def allow(:my_subject, :me, :read), do: {:ok, :my_scoped_subject}
  end

  test "allow scopes the subject" do
    assert {:ok, :my_scoped_subject} =
             Airframe.allowed(:my_subject, :me, :read, ScopingPolicy)
  end
end
