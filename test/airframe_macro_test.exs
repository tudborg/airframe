defmodule AirframeMacroTest do
  use Airframe.Case, async: true
  require Airframe

  defmodule TestContext do
    defmodule TestPolicy do
      use Airframe.Policy
      def allow?(_subject, _context, :a?), do: true
      def allow?(_subject, _context, :b?), do: false

      def allow?(_subject, _context, :a), do: true
      def allow?(_subject, _context, :b), do: false

      def allow?(_subject, _context, :a!), do: true
      def allow?(_subject, _context, :b!), do: false
    end

    use Airframe.Policy, delegate: TestPolicy

    def a?(), do: Airframe.allowed?(:my_subject, :me)
    def b?(), do: Airframe.allowed?(:my_subject, :me)

    def a(), do: Airframe.allowed(:my_subject, :me)
    def b(), do: Airframe.allowed(:my_subject, :me)

    def a!(), do: Airframe.allowed!(:my_subject, :me)
    def b!(), do: Airframe.allowed!(:my_subject, :me)
  end

  test "macro Airframe.allowed?/2 of function Airframe.allowed?/4" do
    assert TestContext.a?()
    refute TestContext.b?()
  end

  test "macro Airframe.allowed/2 of function Airframe.allowed/4" do
    assert {:ok, :my_subject} == TestContext.a()

    assert {:error,
            %Airframe.UnauthorizedError{
              policy: TestContext,
              action: :b,
              context: :me,
              subject: :my_subject
            }} == TestContext.b()
  end

  test "macro Airframe.allowed!/2 of function Airframe.allowed!/4" do
    assert :my_subject == TestContext.a!()
    assert_raise Airframe.UnauthorizedError, fn -> TestContext.b!() end
  end
end
