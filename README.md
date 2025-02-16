# Airframe

Airframe is a libraries for specifying access policies.

A policy is a module implementing checks against a subject and action given an authentication context.
It differentiates itself from other similar libraries by allowing the policy to change the subject.

This makes it possible to combine access scoping and action checking in the same tool.

Documentation can be found at <https://hexdocs.pm/airframe>.

Airframe is a library for generating the frame of a context module.
You still have to add your own business and domain logic, but Airframe will
provide you with the basics.

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

You define a Policy like

```elixir
defmodule MyApp.MyContext.MyPolicy do
  use Airframe.Policy

  @spec allow(subject, action, context)
  def allow(_subject_, _action, _context)do
    true # allow everything by anyone!
  end
end
```

and check against it with `Airframe.check/4`

```elixir
# context == the current authentication, e.g. conn.assigns.current_user, or an API key, etc
with {:ok, subject} <- Airframe.check(subject, action, context, policy) do
  # context is allowed to perform action on subject according to policy.
end
```

There is a macro `Airframe.check/2` that will infer the policy and optionally the action from the calling context.

```elixir
defmodule MyApp.MyContext do
  use Airframe.Policy

  def allow(_subject_, _action, _context)do
    true # allow everything by anyone!
  end

  def create(attr, opts) do
    # infer the action to be the name of the calling function (`create`)
    # and the policy to be the calling module (`MyApp.MyContext`)
    # By using `Airframe.Policy` you automatically require Airframe
    # such that the `Airframe.check/2` macro is available
    with {:ok, subject} <- Airframe.check(subject, context) do
      # context is allowed to perform action on subject according to policy.
    end
  end
end
```

Full example

```elixir
defmodule MyApp.MyContext do
  # Allow this context to be used as a policy,
  # but defer to it's own policy module for the callback function.
  use Airframe.Policy, defer: __MODULE__.Policy

  def list(opts) do
    # we want to list Post
    Post
    # we check that current_user is allowed to do so
    # (the action is derrifed from the calling function - `list` in this case,
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
  # but we narrow the scope to only posts from the auth context (User, in this case)
  @spec allow(subject, action, context)
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


