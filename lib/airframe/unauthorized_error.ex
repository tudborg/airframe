defmodule Airframe.UnauthorizedError do
  defexception [:subject, :context, :action, :policy]

  def message(%__MODULE__{subject: s, context: c, action: a, policy: p}) do
    "policy=#{inspect(p)} did not allow action=#{inspect(a)} on subject=#{show(s)} for context=#{show(c)}"
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
