defmodule Airframe.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      # import Ecto
      # import Ecto.Changeset
      # import Ecto.Query
      import Airframe.Case
    end
  end
end
