# Airframe

[![CI](https://github.com/tudborg/airframe/actions/workflows/elixir.yml/badge.svg)](https://github.com/tudborg/airframe/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/airframe.svg)](https://hex.pm/packages/airframe)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/airframe/)

Airframe is an authorization library.

Documentation can be found at <https://hexdocs.pm/airframe>.

At it's core is the `Airframe.Policy` that you implement for all relevant "subjects".  
A policy is a module implemetning `c:Airframe.Policy.allow/3`, where you implement checks against a subject and action for some "actor" like a `current_user` or session token.

It differentiates itself from other similar libraries by allowing the policy to change the subject, like:
- Changing an `Ecto.Query` to narrow done the scope to the current user.
- Removing changes from an `Ecto.Changeset` based on the current user's access level.
- Completely replacing the subject with an alternative subject.
- 
This makes it possible to combine access scoping and action checking in a single policy.

It can be used anywhere in your application, but is intended to be used in your context modules to
ensure that authorization is handled at the same abstraction level everywhere, regardless of interface.

## Installation

The package can be installed by adding `airframe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:airframe, "~> 0.1.0"}
  ]
end
```

## Examples

You can define a Policy directly in a context:

```elixir
defmodule MyApp.MyContext do
  use Airframe.Policy

  @spec allow(subject, action, actor)
  def allow(_subject_, _action, _actor)do
    true # allow everything by anyone!
  end
end
```

Or more typically in a larger context module, you defer the policy to it's own module:

```elixir
defmodule MyApp.MyContext do
  use Airframe.Policy, defer: MyApp.MyContext.MyPolicy

  # ...
end

defmodule MyApp.MyContext.MyPolicy do
  use Airframe.Policy

  @spec allow(subject, action, actor)
  def allow(_subject_, _action, _actor)do
    true # allow everything by anyone!
  end
end
```

### Authorization

You check against a policy with `Airframe.check/4`

```elixir
with {:ok, subject} <- Airframe.check(subject, action, actor, policy) do
  # actor is allowed to perform action on subject according to policy.
end
```

and it's `raise`ing version `Airframe.check!/4`:

```elixir
Airframe.check(subject, action, actor, policy)
```

which is very convenient if your subject is a schema module or ecto query:

```elixir
def list(opts) do
  Post
  |> Airframe.check!(:read, opts[:current_user], MyPolicy)
  |> Repo.all()
end
```

There is an `Airframe.check/2` and `Airframe.check!/2` macro
that will infer the policy and (optionally) the action from the calling context.

```elixir
defmodule MyApp.MyContext do
  use Airframe.Policy

  def allow(_subject_, _action, _actor) do
    true # allow everything by anyone!
  end

  def create(attr, opts) do
    # infer the action to be the name of the calling function (`create`)
    # and the policy to be the calling module (`MyApp.MyContext`)
    # By using `Airframe.Policy` you automatically require Airframe
    # such that the `Airframe.check/2` macro is available
    with {:ok, subject} <- Airframe.check(subject, actor) do
      # actor is allowed to perform action on subject according to policy.
    end
  end
end
```

### Full Example

```elixir
defmodule MyApp.MyContext do
  # Allow this context to be used as a policy,
  # but defer to it's own policy module for the callback function.
  use Airframe.Policy, defer: __MODULE__.Policy

  def list(opts) do
    # we want to list Post
    Post
    # we check that current_user is allowed to do so
    # (the action is derived from the calling function - `list` in this case,
    # you can ofc. specify the action manually as the second argument to check!/3)
    |> Airframe.check!(opts[:current_user])
    |> Repo.all()
  end

  def get!(id, opts) do
    Post
    |> Airframe.check!(opts[:current_user])
    |> Repo.get!(id)
  end
  
  def create(attrs, opts) do
    with {:ok, attrs} <- Airframe.check(attrs, opts[:current_user]) do
      %Post{}
      |> Post.changeset(attrs)
      |> Repo.insert()
    end
  end

  def update(post, attrs, opts) do
    with {:ok, {post, attrs}} <- Airframe.check({post, attrs}, opts[:current_user]) do
      post
      |> Post.changeset(attrs)
      |> Repo.update()
    end
  end

  # Airframe has special support for Ecto.Changeset.
  # If the subject is a changeset, it will only ever be checked against the policy
  # if it is valid. Otherwise `{:error, changeset}` is returned.

  def update(post, attrs, opts) do
    changeset = Post.changeset(post, attrs)

    with {:ok, changeset} <- Airframe.check(changeset, opts[:current_user]) do
      Repo.update(changeset)
    end
  end

  # ...
end

defmodule MyApp.MyContext.Policy do
  # this is the actual policy module.
  use Airframe.Policy

  # allow the `list` and `get` action on `Post`,
  # but we narrow the scope to only posts from the actor (User, in this case)
  @spec allow(subject, action, actor)
  def allow(Post, action, %User{id: user_id}) when action in [:list, :get] do
    {:ok, from(p in Post, where: p.user_id == ^user_id)}
  end

  # allow a user to create a post if the post attrs user_id matches their user's id
  def allow(attrs, :create, %User{id: user_id}) do
    attrs["user_id"] == user_id
  end

  # allow a user to update a post if the post is their own.
  def allow({%Post{user_id: user_id}, attrs}, :update, %User{id: user_id}), do: true
  def allow({%Post{user_id: _}, attrs}, :update, %User{}), do: false

  # or if you'd rather check on the changeset itself:
  def allow(%Ecto.Changeset{data: %Post{user_id: user_id}}, :update, %User{id: user_id}), do: true
  def allow(%Ecto.Changeset{data: %Post{user_id: _}}, :update, %User{id: _}), do: false

  # having the changeset as the subject also makes it easy to modify it:
  def allow(%Ecto.Changeset{data: %Post{user_id: user_id}}=changeset, :update, %User{id: user_id}) do
    {:ok, Ecto.Changeset.delete_change(changeset, :approved_by_id)}
  end


  # ...
end
```


