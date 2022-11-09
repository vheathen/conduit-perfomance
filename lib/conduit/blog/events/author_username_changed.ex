defmodule Conduit.Blog.Events.AuthorUsernameChanged do
  @derive Jason.Encoder
  defstruct [
    :author_uuid,
    :username
  ]
end
