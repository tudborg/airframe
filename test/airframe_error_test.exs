defmodule AirframeErrorTest do
  use Airframe.Case, async: true
  doctest Airframe.UnauthorizedError

  defmodule Dummy do
    defstruct __meta__: %{
                schema: __MODULE__
              },
              id: nil

    def __schema__(:primary_key), do: [:id]
  end

  test "formats message when Ecto.Schema struct" do
    msg =
      %Airframe.UnauthorizedError{
        policy: Airframe.Policy,
        context: %Dummy{id: :me},
        action: :write,
        subject: %Dummy{id: :subject}
      }
      |> Airframe.UnauthorizedError.message()

    assert msg ==
             "policy=Airframe.Policy did not allow action=:write for " <>
               "context=#AirframeErrorTest.Dummy<id=me> and subject=#AirframeErrorTest.Dummy<id=subject>"
  end
end
