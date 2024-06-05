defmodule Airframe do
  @type policy :: module()
  @type context :: any()
  @type action :: any()
  @type subject :: any()

  @spec allow?(
          policy :: Airframe.policy(),
          context :: Airframe.context(),
          action :: Airframe.action(),
          subject :: Airframe.subject()
        ) :: boolean
  def allow?(policy, context, action, subject) do
    case policy.allow?(context, action, subject) do
      true -> true
      false -> false
    end
  end

  @spec allow(
          policy :: Airframe.policy(),
          context :: Airframe.context(),
          action :: Airframe.action(),
          subject :: Airframe.subject()
        ) :: :ok | {:error, Airframe.UnauthorizedError.t()}
  def allow(policy, context, action, subject) do
    case policy.allow?(context, action, subject) do
      true ->
        :ok

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

  @spec allow!(
          policy :: Airframe.policy(),
          context :: Airframe.context(),
          action :: Airframe.action(),
          subject :: Airframe.subject()
        ) :: :ok | no_return()
  def allow!(policy, context, action, subject) do
    with {:error, error} <- allow(policy, context, action, subject) do
      raise error
    end
  end

  ##
  ## Airframe macros for checking policies.
  ##
  @doc """
  Macro version of `Airframe.allow?/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro allow?(context, subject) do
    quote do
      Airframe.allow?(
        unquote(__CALLER__.module),
        unquote(context),
        unquote(elem(__CALLER__.function, 0)),
        unquote(subject)
      )
    end
  end

  @doc """
  Macro version of `Airframe.allow!/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro allow!(context, subject) do
    quote do
      Airframe.allow!(
        unquote(__CALLER__.module),
        unquote(context),
        unquote(elem(__CALLER__.function, 0)),
        unquote(subject)
      )
    end
  end

  @doc """
  Macro version of `Airframe.allow/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro allow(context, subject) do
    quote do
      Airframe.allow(
        unquote(__CALLER__.module),
        unquote(context),
        unquote(elem(__CALLER__.function, 0)),
        unquote(subject)
      )
    end
  end
end
