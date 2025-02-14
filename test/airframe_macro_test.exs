defmodule AirframeMacroTest do
  use Airframe.Case, async: true
  require Airframe

  defmodule TestContext do
    defmodule TestPolicy do
      use Airframe.Policy
      def allow(_subject, _context, :a), do: true
      def allow(_subject, _context, :b), do: false

      def allow(_subject, _context, :a!), do: true
      def allow(_subject, _context, :b!), do: false

      def allow(nil, _context, :no_subject), do: true
      def allow(_subject, _context, :custom_action), do: true
    end

    use Airframe.Policy, delegate: TestPolicy

    def a(), do: Airframe.check(:my_subject, :me)
    def b(), do: Airframe.check(:my_subject, :me)

    def a!(), do: Airframe.check!(:my_subject, :me)
    def b!(), do: Airframe.check!(:my_subject, :me)

    def with_action(), do: Airframe.check(:my_subject, :me, :custom_action)
  end

  test "macro Airframe.check/2 of function Airframe.check/4" do
    assert {:ok, :my_subject} == TestContext.a()

    assert {:error, {:unauthorized, _}} = TestContext.b()
  end

  test "macro Airframe.check!/2 of function Airframe.check!/4" do
    assert :my_subject == TestContext.a!()
    assert_raise Airframe.UnauthorizedError, fn -> TestContext.b!() end
  end

  test "macro custom action" do
    assert TestContext.with_action()
  end
end
