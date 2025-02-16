defmodule Airframe.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Airframe.Case
    end
  end
end
