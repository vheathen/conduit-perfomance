defmodule Conduit.Blog.Supervisor do
  use Supervisor

  alias Conduit.Blog

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init(
      [
        Blog.Projectors.Author,
        # Blog.Projectors.Article,
        # Blog.Projectors.Tag,
        Blog.Workflows.CreateAuthorFromUser,
        Blog.Workflows.ChangeAuthorUsernameFromUser
      ],
      strategy: :one_for_one
    )
  end
end
