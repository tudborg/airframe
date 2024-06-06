defmodule Airframe.Policy do
  @moduledoc """
  The Policy behaviour.

  To use this module, you must implement the `Airframe.Policy.allow?/3` callback.

  When using this module (`use Airframe.Policy`), an automatic implementation of
  `allow?/3` is generated that always returns false, such that you only have
  to implement the `allow?/3` callback for any _allowed_ combinations of
  `context`, `action`, and `subject`.
  """

  @doc """
  Checks if the `context` is allowed to perform the `action` on the `subject`.

  NOTE: that the `subject` is passed through from the checking side,
  and could be anything.

  """
  @callback allow?(
              subject :: Airframe.subject(),
              context :: Airframe.context(),
              action :: Airframe.action()
            ) :: boolean

  ##
  ## Functions
  ##

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
    case allowed?(subject, context, action, policy) do
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

  @doc """
  Automatically implements the `Airframe.Policy` behaviour.

  ## Options

  * `delegate` - If provided, it is the module to delegate to for policy checking instead of this module.


  ## Example


      defmodule MyApp.Context do
        # simply
        use Airframe.Policy

        # or if you want to implement `allow?/3` in a different module:
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
          def allow?(subject, context, action) do
            unquote(module).allow?(subject, context, action)
          end
        end

      # we are not delegating, so check if we should auto-implement a default
      :error ->
        case Keyword.fetch(opts, :default) do
          {:ok, default} when is_boolean(default) ->
            quote do
              def allow?(_, _, _), do: unquote(default)
            end

          :error ->
            []
        end
    end
  end
end
