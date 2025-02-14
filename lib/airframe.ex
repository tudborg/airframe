defmodule Airframe do
  @type subject :: any()
  @type context :: any()
  @type action :: any()
  @type policy :: module()

  # Policy
  defdelegate check(action, subject, context, policy), to: Airframe.Policy
  defdelegate check!(action, subject, context, policy), to: Airframe.Policy

  # Resource
  defdelegate scope(queryable, scope), to: Airframe.Resource

  ##
  ## Macros
  ##

  @doc """
  Macro version of `Airframe.check!/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro check!(action \\ nil, subject, context) do
    action =
      action ||
        case __CALLER__.function do
          nil -> raise "not called inside a function"
          {name, _arity} -> name
        end

    quote do
      Airframe.check!(
        unquote(action),
        unquote(subject),
        unquote(context),
        unquote(__CALLER__.module)
      )
    end
  end

  @doc """
  Macro version of `Airframe.check/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro check(action \\ nil, subject, context) do
    action =
      action ||
        case __CALLER__.function do
          nil -> raise "not called inside a function"
          {name, _arity} -> name
        end

    quote do
      Airframe.check(
        unquote(action),
        unquote(subject),
        unquote(context),
        unquote(__CALLER__.module)
      )
    end
  end
end
