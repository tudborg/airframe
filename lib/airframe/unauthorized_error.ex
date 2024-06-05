defmodule Airframe.UnauthorizedError do
  defexception [:policy, :context, :action, :subject]

  def message(%__MODULE__{policy: p, context: c, action: a, subject: s}) do
    "policy=#{inspect(p)} did not allow action=#{inspect(a)} for context=#{show(c)} and subject=#{show(s)}"
  end

  # show an ecto schema struct, just pick the primary key fields:
  defp show(%module{__meta__: %{schema: schema}} = struct) do
    identity =
      schema.__schema__(:primary_key)
      |> Enum.map(&"#{&1}=#{Map.get(struct, &1)}")
      |> Enum.join(",")

    "##{inspect(module)}<#{identity}>"
  end

  # show anything else:
  defp show(value), do: inspect(value)
end
