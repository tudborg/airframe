defmodule Airframe.Policy do
  @moduledoc """
  The Policy behaviour, using macro, and defaults.

  ## Examples

      defmodule MyApp.Policy do
        use Airframe.Policy

        def allow(%User{id: user_id}, :update, %{current_user: %User{id: user_id}}), do: true
        def allow(%User{id: user_id}, :update, %{current_user: %User{id: other_id}}), do: false
      end
  """

  @doc """
  Checks if the `action` is allowed on `subject` by `context`.

  Can return plain true/false, or a tuple `{:ok, scoped_subject}` to still allow the action,
  while narrowing the scope of the original subject.
  This is useful if the original subject is an `Ecto.Query` or similar that can be narrowed down.
  Can also return `{:error, reason :: any()}` which will be passed along to the caller.
  """
  @callback allow(
              subject :: Airframe.subject(),
              action :: Airframe.action(),
              context :: Airframe.context()
            ) :: boolean() | {:ok, scoped_subject :: any()} | {:error, any()}

  @doc """
  Checks if the `action` is allowed on `subject` for `context` by `policy`.

  If the `ecto_changeset` feature flag is enabled (default: true),
  this function will return `{:error, changeset}` if the `subject` is an `Ecto.Changeset` and is marked as invalid.
  """
  @spec check(
          subject :: Airframe.subject(),
          action :: Airframe.action(),
          context :: Airframe.context(),
          policy :: Airframe.policy()
        ) ::
          {:ok, narrowed_subject :: Airframe.subject()}
          | {:error, :unauthorized}
          | {:error, any()}

  # if ecto changeset support is enabled, `check/4`
  # will always return {:error, changeset} if the changeset is marked invalid.
  if Airframe.Feature.supported?(:ecto_changeset) do
    def check(
          %{__struct__: :"Elixir.Ecto.Changeset", valid?: false} = changeset,
          _action,
          _context,
          _policy
        ) do
      {:error, changeset}
    end
  end

  def check(subject, action, context, policy) do
    case policy.allow(subject, action, context) do
      # allow with same subject:
      true ->
        {:ok, subject}

      # dont allow:
      false ->
        {:error,
         {:unauthorized,
          %Airframe.UnauthorizedError{
            subject: subject,
            action: action,
            context: context,
            policy: policy
          }}}

      # allowed, but policy wants to define the scope:
      {:ok, scoped} ->
        {:ok, scoped}

      # policy error. forward to caller:
      {:error, reason} ->
        {:error, reason}

      # defer policy check to another policy module
      {:defer, new_policy} ->
        check(subject, action, context, new_policy)
    end
  end

  @doc """
  Checks if the `action` is allowed on `subject` for `context` by `policy`.

  Like `check/4`, but raises an `Airframe.UnauthorizedError` if the action is not allowed.
  """
  @spec check!(
          subject :: Airframe.subject(),
          action :: Airframe.action(),
          context :: Airframe.context(),
          policy :: Airframe.policy()
        ) :: Airframe.subject() | no_return()
  def check!(subject, action, context, policy) do
    unwrap!(check(subject, action, context, policy))
  end

  @doc false
  def unwrap!(result) do
    case result do
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
  Set up the module as an `Airframe.Policy`.

  ## Options

  * `defer` - If provided, it is the module to defer to for policy checking instead of this module.
  * `default` - If provided, a catch-all `allow/3` is appended that always returns this value.
    This is useful for policies that always allow or deny everything by default. If not provided,
    the user is responsible for handling all cases in their policy module.

  ## Example

      defmodule MyApp.Context do
        # simply
        use Airframe.Policy

        # or if you want to implement `c:Airframe.Policy.allow/3` in a different module:
        use Airframe.Policy, defer: MyApp.Context.Policy
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

    case Keyword.fetch(opts, :defer) do
      # are we delegating to another module?
      {:ok, module} when is_atom(module) ->
        quote do
          def allow(action, subject, context) do
            {:defer, unquote(module)}
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
