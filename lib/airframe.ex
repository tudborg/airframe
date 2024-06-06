defmodule Airframe do
  @type subject :: any()
  @type context :: any()
  @type action :: any()
  @type policy :: module()

  @spec allowed?(
          subject :: Airframe.subject(),
          context :: Airframe.context(),
          action :: Airframe.action(),
          policy :: Airframe.policy()
        ) :: boolean
  def allowed?(subject, context, action, policy) do
    case policy.allow?(subject, context, action) do
      true -> true
      false -> false
    end
  end

  @spec allowed(
          subject :: Airframe.subject(),
          context :: Airframe.context(),
          action :: Airframe.action(),
          policy :: Airframe.policy()
        ) :: :ok | {:error, Airframe.UnauthorizedError.t()}
  def allowed(subject, context, action, policy) do
    case policy.allow?(subject, context, action) do
      true ->
        {:ok, subject}

      false ->
        {:error,
         %Airframe.UnauthorizedError{
           policy: policy,
           context: context,
           action: action,
           subject: subject
         }}
    end
  end

  @spec allowed!(
          subject :: Airframe.subject(),
          context :: Airframe.context(),
          action :: Airframe.action(),
          policy :: Airframe.policy()
        ) :: :ok | no_return()
  def allowed!(subject, context, action, policy) do
    case allowed(subject, context, action, policy) do
      {:ok, subject} -> subject
      {:error, error} -> raise error
    end
  end

  ##
  ## Airframe macros for checking policies.
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
