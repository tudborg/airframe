defmodule AirframeTest do
  use Airframe.Case, async: true
  doctest Airframe

  defmodule Context do
    use Airframe.Policy
    def allow(_, :me, :read), do: true
    def allow(_, :me, :write), do: false
    def allow(_, :me, :error), do: {:error, :reason}
  end

  test "allowed/4" do
    assert Airframe.check(:my_subject, :me, :read, Context) == {:ok, :my_subject}

    assert {:error, {:unauthorized, _}} = Airframe.check(:my_subject, :me, :write, Context)

    assert Airframe.check(:my_subject, :me, :error, Context) ==
             {:error, :reason}
  end

  test "allowed!/4" do
    assert_raise Airframe.UnauthorizedError, fn ->
      Airframe.check!(:my_subject, :me, :write, Context)
    end

    assert_raise Airframe.PolicyError, fn ->
      Airframe.check!(:my_subject, :me, :error, Context)
    end
  end
end
