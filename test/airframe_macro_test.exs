defmodule AirframeMacroTest do
  use Airframe.Case, async: true
  require Airframe

  defmodule TestContext do
    defmodule TestPolicy do
      use Airframe.Policy
      def allow(:a, _subject, _context), do: true
      def allow(:b, _subject, _context), do: false

      def allow(:a!, _subject, _context!), do: true
      def allow(:b!, _subject, _context!), do: false

      def allow(:no_subject, nil, _context), do: true
      def allow(:custom_action, _subject, _context), do: true
    end

    use Airframe.Policy, delegate: TestPolicy

    def a(), do: Airframe.check(:my_subject, :me)
    def b(), do: Airframe.check(:my_subject, :me)

    def a!(), do: Airframe.check!(:my_subject, :me)
    def b!(), do: Airframe.check!(:my_subject, :me)

    def with_action(), do: Airframe.check(:custom_action, :my_subject, :me)
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
