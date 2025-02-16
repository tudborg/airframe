defmodule Airframe do
  @moduledoc """
  Airframe is an authorization library.

  To use Airframe, you must implement the `Airframe.Policy` behaviour.

  In your policy module `use Airframe.Policy`:

      defmodule MyApp.MyContext.MyPolicy do
        use Airframe.Policy

        @spec allow(subject, action, context)
        def allow(_subject_, _action, _context)do
          true # allow everything by anyone!
        end
      end

  To check against a policy, you use `Airframe.check/4`

      def delete(subject, opts) do
        # subject - the object to be acted upon
        # action - the action to be performed on the subject
        # context - the current authentication, e.g. conn.assigns.current_user, or an API key, etc
        # policy - the module that implements the `Airframe.Policy` behaviour to check against
        with {:ok, subject} <- Airframe.check(subject, action, context, policy) do
          # context is allowed to perform action on subject according to policy.
        end
      end

  Or `Airframe.check!/4`:

      def list(opts) do
        Post
        |> Airframe.check!(:read, opts[:current_user], MyPolicy)
        |> Repo.all()
      end
  """

  @typedoc """
  The subject of the action.

  For "read" actions, this is typically a schema or query that the policy
  is expected to narrow down access to.

  For "write" actions, this is typically a struct or changeset that the policy
  is expected to validate authorization for.
  """
  @type subject :: any()

  @typedoc """
  The context of the action.

  This is typically the current user, session token, or some other
  value that represents the actor of the action.
  """
  @type context :: any()

  @typedoc """
  The action to be performed on the subject.

  This is typically an atom that represents the action to be performed,
  such as `:create`, `:read`, `:update`, `:delete`, however it can be any value.
  """
  @type action :: any()

  @typedoc """
  The policy module that implements the `Airframe.Policy` behaviour.
  """
  @type policy :: module()

  # Policy
  defdelegate check(subject, action, context, policy), to: Airframe.Policy
  defdelegate check!(subject, action, context, policy), to: Airframe.Policy

  ##
  ## Macros
  ##

  @doc """
  Macro version of `Airframe.check/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.

    ## Example

      defmodule MyApp.MyContext do
        use Airframe.Policy
        # ...
        def create(attr, opts) do
          # infer the action to be the name of the calling function (`create`)
          # and the policy to be the calling module (`MyApp.MyContext`)
          changeset = %Post{} |> Post.changeset(attr)
          with {:ok, changeset} <- Airframe.check(changeset, context) do
            # context is allowed to perform action on changeset according to policy.
          end
        end
      end
  """
  defmacro check(subject, action \\ nil, context) do
    action =
      action ||
        case __CALLER__.function do
          nil -> raise "not called inside a function"
          {name, _arity} -> name
        end

    quote do
      Airframe.check(
        unquote(subject),
        unquote(action),
        unquote(context),
        unquote(__CALLER__.module)
      )
    end
  end

  @doc """
  Macro version of `Airframe.check!/4`.

  Infers the policy from the calling module,
  and the action from the calling function name.
  """
  defmacro check!(subject, action \\ nil, context) do
    action =
      action ||
        case __CALLER__.function do
          nil -> raise "not called inside a function"
          {name, _arity} -> name
        end

    quote do
      Airframe.check!(
        unquote(subject),
        unquote(action),
        unquote(context),
        unquote(__CALLER__.module)
      )
    end
  end
end
