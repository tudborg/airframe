defmodule Airframe.UnauthorizedError do
  defexception [:subject, :action, :actor, :policy, :hint]

  def message(%__MODULE__{subject: s, actor: c, action: a, policy: p, hint: h}) do
    "policy=#{inspect(p)} did not allow action=#{inspect(a)}" <>
      " on subject=#{show(s)} for actor=#{show(c)}" <>
      if h, do: " (hint=#{h})", else: ""
  end

  # show an ecto schema struct, just pick the primary key fields:
  defp show(%module{__meta__: %{schema: schema}} = struct) do
    identity =
      schema.__schema__(:primary_key)
      |> Enum.map(&"#{&1}=#{Map.get(struct, &1)}")
      |> Enum.join(",")

    "##{inspect(module)}<#{identity}>"
  end

  defp show(t) when is_tuple(t) do
    "{#{Tuple.to_list(t) |> Enum.map(&show/1) |> Enum.join(", ")}}"
  end

  defp show(l) when is_list(l) do
    "[#{Enum.map(l, &show/1) |> Enum.join(", ")}]"
  end

  # show anything else:
  defp show(value), do: inspect(value)
end
