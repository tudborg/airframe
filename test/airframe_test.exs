defmodule AirframeTest do
  use Airframe.Case, async: true
  doctest Airframe

  defmodule Context do
    use Airframe.Policy
    def allow?(_, :me, :read), do: true
    def allow?(_, :me, :write), do: false
  end

  test "allowed?/4" do
    assert Airframe.allowed?(:my_subject, :me, :read, Context)
    refute Airframe.allowed?(:my_subject, :me, :write, Context)
  end

  test "allowed/4" do
    assert Airframe.allowed(:my_subject, :me, :read, Context) == {:ok, :my_subject}

    assert Airframe.allowed(:my_subject, :me, :write, Context) ==
             {:error,
              %Airframe.UnauthorizedError{
                policy: Context,
                context: :me,
                action: :write,
                subject: :my_subject
              }}
  end

  test "allowed!/4" do
    assert_raise Airframe.UnauthorizedError, fn ->
      Airframe.allowed!(:my_subject, :me, :write, Context)
    end
  end
end
