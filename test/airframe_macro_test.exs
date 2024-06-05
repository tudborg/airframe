defmodule AirframeMacroTest do
  use Airframe.Case, async: true
  require Airframe

  defmodule TestContext do
    defmodule TestPolicy do
      use Airframe.Policy
      def allow?(_context, :a?, _subject), do: true
      def allow?(_context, :b?, _subject), do: false

      def allow?(_context, :a, _subject), do: true
      def allow?(_context, :b, _subject), do: false

      def allow?(_context, :a!, _subject), do: true
      def allow?(_context, :b!, _subject), do: false
    end

    use Airframe.Policy, delegate: TestPolicy

    def a?(), do: Airframe.allow?(:me, %{})
    def b?(), do: Airframe.allow?(:me, %{})

    def a(), do: Airframe.allow(:me, %{})
    def b(), do: Airframe.allow(:me, %{})

    def a!(), do: Airframe.allow!(:me, %{})
    def b!(), do: Airframe.allow!(:me, %{})
  end

  test "macro Airframe.allow?/2 of function Airframe.allow?/4" do
    assert TestContext.a?()
    refute TestContext.b?()
  end

  test "macro Airframe.allow/2 of function Airframe.allow/4" do
    assert :ok == TestContext.a()

    assert {:error,
            %Airframe.UnauthorizedError{
              policy: TestContext,
              action: :b,
              context: :me,
              subject: %{}
            }} == TestContext.b()
  end

  test "macro Airframe.allow!/2 of function Airframe.allow!/4" do
    assert :ok = TestContext.a!()
    assert_raise Airframe.UnauthorizedError, fn -> TestContext.b!() end
  end
end
