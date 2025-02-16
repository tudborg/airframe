defmodule Airframe.Feature do
  @moduledoc false

  @feature_flags_and_defaults [
    ecto: match?({:module, _}, Code.ensure_compiled(Ecto)),
    ecto_changeset: match?({:module, _}, Code.ensure_compiled(Ecto.Changeset))
  ]
  @features Application.compile_env(:airframe, :feature, [])

  for {flag, default} <- @feature_flags_and_defaults do
    supported = if Keyword.has_key?(@features, flag), do: @features[flag], else: default
    def supported?(unquote(flag)), do: unquote(supported)
  end
end
