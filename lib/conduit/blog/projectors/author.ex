defmodule Conduit.Blog.Projectors.Author do
  use Commanded.Projections.Ecto,
    application: Conduit.App,
    name: "Blog.Projectors.Author",
    consistency: :eventual

  alias Conduit.Blog.Projections.{Author, Feed}

  alias Conduit.Blog.Events.{
    AuthorCreated,
    AuthorUsernameChanged,
    AuthorFollowed,
    AuthorUnfollowed
  }

  alias Conduit.Repo

  project(%AuthorCreated{} = author, fn multi ->
    Ecto.Multi.insert(multi, :author, %Author{
      uuid: author.author_uuid,
      user_uuid: author.user_uuid,
      username: author.username,
      bio: nil,
      image: nil
    })
  end)

  project(%AuthorUsernameChanged{author_uuid: author_uuid, username: username}, fn multi ->
    update_author(multi, author_uuid, username: username)
  end)

  project(
    %AuthorFollowed{author_uuid: author_uuid, followed_by_author_uuid: follower_uuid},
    fn multi ->
      multi
      |> Ecto.Multi.update_all(:author, author_query(author_uuid),
        push: [followers: follower_uuid]
      )
      |> Ecto.Multi.run(:feed, fn _repo, _changes ->
        copy_author_articles_into_feed(author_uuid, follower_uuid)
      end)
    end
  )

  project(
    %AuthorUnfollowed{author_uuid: author_uuid, unfollowed_by_author_uuid: follower_uuid},
    fn multi ->
      multi
      |> Ecto.Multi.update_all(:author, author_query(author_uuid),
        pull: [followers: follower_uuid]
      )
      |> Ecto.Multi.delete_all(:feed, author_follower_feed_query(author_uuid, follower_uuid))
    end
  )

  defp author_query(author_uuid) do
    from(a in Author, where: a.uuid == ^author_uuid)
  end

  defp update_author(multi, author_uuid, changes) do
    changes = Keyword.put(changes, :updated_at, DateTime.utc_now())
    Ecto.Multi.update_all(multi, :user, author_query(author_uuid), set: changes)
  end

  defp author_follower_feed_query(author_uuid, follower_uuid) do
    from(f in Feed, where: f.author_uuid == ^author_uuid and f.follower_uuid == ^follower_uuid)
  end

  # Copy the articles published by the author into the follower's feed
  defp copy_author_articles_into_feed(author_uuid, follower_uuid) do
    {:ok, author} = Ecto.UUID.dump(author_uuid)
    {:ok, follower} = Ecto.UUID.dump(follower_uuid)

    query(
      """
      INSERT INTO blog_feed_articles (article_uuid, follower_uuid, author_uuid, published_at, inserted_at, updated_at)
      SELECT uuid, $1, author_uuid, published_at, inserted_at, updated_at
      FROM blog_articles
      WHERE author_uuid = $2;
      """,
      [follower, author]
    )
  end

  defp query(sql, values) do
    Ecto.Adapters.SQL.query(Repo, sql, values)
  end
end
