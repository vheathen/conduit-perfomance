defmodule Conduit.Blog.Commands.ChangeAuthorUsername do
  defstruct author_uuid: "",
            username: ""

  use ExConstructor
  use Vex.Struct

  alias Conduit.Blog.Commands.ChangeAuthorUsername

  validates(:author_uuid, uuid: true)

  validates(:username,
    presence: [message: "can't be empty"],
    format: [with: ~r/^[a-z0-9\-]+$/, allow_nil: true, allow_blank: true, message: "is invalid"],
    string: true
  )

  @doc """
  Assign a unique identity
  """
  def assign_uuid(%ChangeAuthorUsername{} = set_author_username, uuid) do
    %ChangeAuthorUsername{set_author_username | author_uuid: uuid}
  end
end
