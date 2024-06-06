defmodule Airframe do
  @type subject :: any()
  @type context :: any()
  @type action :: any()
  @type policy :: module()

  # Policy
  defdelegate allowed?(subject, context, action, policy), to: Airframe.Policy
  defdelegate allowed(subject, context, action, policy), to: Airframe.Policy
  defdelegate allowed!(subject, context, action, policy), to: Airframe.Policy

  # Context
  defdelegate tag(subject, context), to: Airframe.Context
  defdelegate context(subject), to: Airframe.Context
  defdelegate context!(subject), to: Airframe.Context
  defdelegate same?(subject_context, trusted_context), to: Airframe.Context

  # Resource
  defdelegate scope(queryable, context, opts \\ []), to: Airframe.Resource

  ##
  ## Macros
  ##

  @doc """
  Macro version of `Airframe.allowed?/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro allowed?(subject \\ nil, context, action \\ nil) do
    action = action || elem(__CALLER__.function, 0)

    quote do
      Airframe.allowed?(
        unquote(subject),
        unquote(context),
        unquote(action),
        unquote(__CALLER__.module)
      )
    end
  end

  @doc """
  Macro version of `Airframe.allowed!/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro allowed!(subject \\ nil, context, action \\ nil) do
    action = action || elem(__CALLER__.function, 0)

    quote do
      Airframe.allowed!(
        unquote(subject),
        unquote(context),
        unquote(action),
        unquote(__CALLER__.module)
      )
    end
  end

  @doc """
  Macro version of `Airframe.allowed/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro allowed(subject \\ nil, context, action \\ nil) do
    action = action || elem(__CALLER__.function, 0)

    quote do
      Airframe.allowed(
        unquote(subject),
        unquote(context),
        unquote(action),
        unquote(__CALLER__.module)
      )
    end
  end
end
