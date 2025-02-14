defmodule AirframeTest do
  use Airframe.Case, async: true
  doctest Airframe

  defmodule Context do
    use Airframe.Policy
    def allow(:read, _, :me), do: true
    def allow(:write, _, :me), do: false
    def allow(:error, _, :me), do: {:error, :reason}
  end

  test "allowed/4" do
    assert Airframe.check(:read, :my_subject, :me, Context) == {:ok, :my_subject}

    assert {:error, {:unauthorized, _}} = Airframe.check(:write, :my_subject, :me, Context)

    assert Airframe.check(:error, :my_subject, :me, Context) ==
             {:error, :reason}
  end

  test "allowed!/4" do
    assert_raise Airframe.UnauthorizedError, fn ->
      Airframe.check!(:write, :my_subject, :me, Context)
    end

    assert_raise Airframe.PolicyError, fn ->
      Airframe.check!(:error, :my_subject, :me, Context)
    end
  end
end
