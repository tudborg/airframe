defmodule AirframeTest do
  use Airframe.Case, async: true
  doctest Airframe

  defmodule Context do
    use Airframe.Policy
    def allow?(:me, :read, _), do: true
    def allow?(:me, :write, _), do: false
  end

  test "allow?/4" do
    assert Airframe.allow?(Context, :me, :read, %{})
    refute Airframe.allow?(Context, :me, :write, %{})
  end

  test "allow/4" do
    assert Airframe.allow(Context, :me, :read, %{}) == :ok

    assert Airframe.allow(Context, :me, :write, %{}) ==
             {:error,
              %Airframe.UnauthorizedError{
                policy: Context,
                context: :me,
                action: :write,
                subject: %{}
              }}
  end

  test "allow!/4" do
    assert_raise Airframe.UnauthorizedError, fn ->
      Airframe.allow!(Context, :me, :write, %{})
    end
  end
end
