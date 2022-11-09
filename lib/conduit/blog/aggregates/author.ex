defmodule Conduit.Blog.Aggregates.Author do
  defstruct uuid: nil,
            user_uuid: nil,
            username: nil,
            bio: nil,
            image: nil,
            followed_by_authors: MapSet.new()

  alias Conduit.Blog.Aggregates.Author
  alias Conduit.Blog.Commands.{CreateAuthor, ChangeAuthorUsername, FollowAuthor, UnfollowAuthor}

  alias Conduit.Blog.Events.{
    AuthorCreated,
    AuthorUsernameChanged,
    AuthorFollowed,
    AuthorUnfollowed
  }

  # @doc """
  # Creates an author
  # """
  def execute(%Author{uuid: nil}, %CreateAuthor{} = create) do
    %AuthorCreated{
      author_uuid: create.author_uuid,
      user_uuid: create.user_uuid,
      username: create.username
    }
  end

  def execute(%Author{}, %CreateAuthor{}) do
    {:error, :already_created}
  end

  # any other commands should reach existing aggregates only
  def execute(%Author{uuid: nil}, _any_command) do
    {:error, :unknown_author}
  end

  def execute(%Author{username: same_username}, %ChangeAuthorUsername{username: same_username}) do
    :ok
  end

  def execute(%Author{uuid: author_uuid}, %ChangeAuthorUsername{username: new_username}) do
    %AuthorUsernameChanged{
      author_uuid: author_uuid,
      username: new_username
    }
  end

  # @doc """
  # Follow an author
  # """
  def execute(%Author{uuid: author_uuid} = author, %FollowAuthor{follower_uuid: follower_uuid}) do
    case is_follower?(author, follower_uuid) do
      true ->
        nil

      false ->
        %AuthorFollowed{
          author_uuid: author_uuid,
          followed_by_author_uuid: follower_uuid
        }
    end
  end

  # @doc """
  # Unfollow an author
  # """
  def execute(%Author{uuid: author_uuid} = author, %UnfollowAuthor{unfollower_uuid: follower_uuid}) do
    case is_follower?(author, follower_uuid) do
      true ->
        %AuthorUnfollowed{
          author_uuid: author_uuid,
          unfollowed_by_author_uuid: follower_uuid
        }

      false ->
        nil
    end
  end

  # def execute(author, command) do
  #   require Logger
  #   Logger.error(inspect(author), label: "Author")
  #   Logger.error(inspect(command), label: "Command")
  # end

  # state mutators

  def apply(%Author{} = author, %AuthorCreated{} = created) do
    %Author{
      author
      | uuid: created.author_uuid,
        user_uuid: created.user_uuid,
        username: created.username
    }
  end

  def apply(%Author{} = author, %AuthorUsernameChanged{username: new_username}) do
    %Author{author | username: new_username}
  end

  def apply(%Author{followed_by_authors: followers} = author, %AuthorFollowed{
        followed_by_author_uuid: follower_uuid
      }) do
    %Author{author | followed_by_authors: MapSet.put(followers, follower_uuid)}
  end

  def apply(%Author{followed_by_authors: followers} = author, %AuthorUnfollowed{
        unfollowed_by_author_uuid: unfollower_uuid
      }) do
    %Author{author | followed_by_authors: MapSet.delete(followers, unfollower_uuid)}
  end

  # private helpers

  defp is_follower?(%Author{followed_by_authors: followers}, follower_uuid) do
    MapSet.member?(followers, follower_uuid)
  end
end
