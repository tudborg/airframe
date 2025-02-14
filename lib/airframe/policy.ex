defmodule Airframe.Policy do
  @moduledoc """
  The Policy behaviour.

  To use this module, you must implement the `Airframe.Policy.allow/3` callback.
  """

  @doc """
  Checks if the `action` is allowed on `subject` by `context`.

  Can return plain true/false, or a tuple `{:ok, scoped_subject}` to still allow the action,
  while narrowing the scope of the original subject.
  This is useful if the original subject is an `Ecto.Query` or similar that can be narrowed down.
  Can also return `{:error, reason :: any()}` which will be passed along to the caller.
  """
  @callback allow(
              action :: Airframe.action(),
              subject :: Airframe.subject(),
              context :: Airframe.context()
            ) :: boolean() | {:ok, scoped_subject :: any()} | {:error, any()}

  @spec check(
          action :: Airframe.action(),
          subject :: Airframe.subject(),
          context :: Airframe.context(),
          policy :: Airframe.policy()
        ) ::
          {:ok, narrowed_subject :: Airframe.subject()}
          | {:error, :unauthorized}
          | {:error, any()}
  def check(action, subject, context, policy) do
    case policy.allow(action, subject, context) do
      # allow with same subject:
      true ->
        {:ok, subject}

      # dont allow:
      false ->
        {:error,
         {:unauthorized,
          %Airframe.UnauthorizedError{
            policy: policy,
            context: context,
            action: action,
            subject: subject
          }}}

      # allowed, but policy wants to define the scope:
      {:ok, scoped} ->
        {:ok, scoped}

      # policy error. forward to caller:
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec check!(
          action :: Airframe.action(),
          subject :: Airframe.subject(),
          context :: Airframe.context(),
          policy :: Airframe.policy()
        ) :: Airframe.subject() | no_return()
  def check!(action, subject, context, policy) do
    case check(action, subject, context, policy) do
      {:ok, subject} ->
        subject

      {:error, {:unauthorized, %Airframe.UnauthorizedError{} = error}} ->
        raise error

      {:error, reason} when is_binary(reason) ->
        raise Airframe.PolicyError, message: reason

      {:error, reason} ->
        raise Airframe.PolicyError, message: inspect(reason)
    end
  end

  @doc """
  Automatically implements the `Airframe.Policy` behaviour.

  ## Options

  * `delegate` - If provided, it is the module to delegate to for policy checking instead of this module.


  ## Example


      defmodule MyApp.Context do
        # simply
        use Airframe.Policy

        # or if you want to implement `allow/3` in a different module:
        use Airframe.Policy, delegate: MyApp.Context.Policy
      end
  """
  defmacro __using__(opts) do
    quote do
      require Airframe
      @behaviour Airframe.Policy
      @before_compile Airframe.Policy
      @airframe_opts unquote(opts)
    end
  end

  @doc false
  defmacro __before_compile__(%Macro.Env{} = env) do
    opts = Module.get_attribute(env.module, :airframe_opts, [])

    case Keyword.fetch(opts, :delegate) do
      # are we delegating to another module?
      {:ok, module} when is_atom(module) ->
        quote do
          def allow(action, subject, context) do
            unquote(module).allow(action, subject, context)
          end
        end

      # we are not delegating, so check if we should auto-implement a default
      :error ->
        case Keyword.fetch(opts, :default) do
          {:ok, default} when is_boolean(default) ->
            quote do
              def allow(_, _, _), do: unquote(default)
            end

          :error ->
            []
        end
    end
  end
end
