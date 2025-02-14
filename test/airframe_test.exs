defmodule AirframeTest do
  use Airframe.Case, async: true
  doctest Airframe

  defmodule Context do
    use Airframe.Policy
    def allow(_, :read, :me), do: true
    def allow(_, :write, :me), do: false
    def allow(_, :error, :me), do: {:error, :reason}
  end

  test "allowed/4" do
    assert Airframe.check(:my_subject, :read, :me, Context) == {:ok, :my_subject}

    assert {:error, {:unauthorized, _}} = Airframe.check(:my_subject, :write, :me, Context)

    assert Airframe.check(:my_subject, :error, :me, Context) ==
             {:error, :reason}
  end

  test "allowed!/4" do
    assert_raise Airframe.UnauthorizedError, fn ->
      Airframe.check!(:my_subject, :write, :me, Context)
    end

    assert_raise Airframe.PolicyError, fn ->
      Airframe.check!(:my_subject, :error, :me, Context)
    end
  end
end
