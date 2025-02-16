defmodule AirframeTest do
  use Airframe.Case, async: true
  doctest Airframe

  defmodule MyPolicy do
    use Airframe.Policy
    def allow(_, :read, :me), do: true
    def allow(_, :write, :me), do: false
    def allow(_, :error, :me), do: {:error, :reason}
  end

  test "allowed/4" do
    assert Airframe.check(:my_subject, :read, :me, MyPolicy) == {:ok, :my_subject}

    assert {:error, {:unauthorized, _}} = Airframe.check(:my_subject, :write, :me, MyPolicy)

    assert Airframe.check(:my_subject, :error, :me, MyPolicy) ==
             {:error, :reason}
  end

  test "allowed!/4" do
    assert_raise Airframe.UnauthorizedError, fn ->
      Airframe.check!(:my_subject, :write, :me, MyPolicy)
    end

    assert_raise Airframe.PolicyError, fn ->
      Airframe.check!(:my_subject, :error, :me, MyPolicy)
    end
  end
end
