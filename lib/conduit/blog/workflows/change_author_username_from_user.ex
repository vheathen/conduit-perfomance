defmodule Conduit.Blog.Workflows.ChangeAuthorUsernameFromUser do
  use Commanded.Event.Handler,
    application: Conduit.App,
    name: "Blog.Workflows.ChangeAuthorUsernameFromUser"

  # consistency: :strong

  alias Conduit.Accounts.Events.UsernameChanged
  alias Conduit.Blog

  def handle(%UsernameChanged{user_uuid: user_uuid, username: username}, _metadata) do
    with {:ok, _author} <-
           Blog.change_author_username(%{user_uuid: user_uuid, username: username}) do
      :ok
    end
  end
end
