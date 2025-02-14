defmodule Airframe do
  @type subject :: any()
  @type context :: any()
  @type action :: any()
  @type policy :: module()

  # Policy
  # TODO: Should allowed be named `check` instead?
  defdelegate allowed(subject, context, action, policy), to: Airframe.Policy
  defdelegate allowed!(subject, context, action, policy), to: Airframe.Policy

  # Resource
  defdelegate scope(queryable, scope), to: Airframe.Resource

  ##
  ## Macros
  ##

  @doc """
  Macro version of `Airframe.allowed!/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro allowed!(subject, context, action \\ nil) do
    action =
      action ||
        case __CALLER__.function do
          nil -> raise "not called inside a function"
          {name, _arity} -> name
        end

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
  defmacro allowed(subject, context, action \\ nil) do
    action =
      action ||
        case __CALLER__.function do
          nil -> raise "not called inside a function"
          {name, _arity} -> name
        end

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
