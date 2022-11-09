defmodule Conduit.Blog.Projectors.Article do
  use Commanded.Projections.Ecto,
    application: Conduit.App,
    name: "Blog.Projectors.Article",
    consistency: :eventual

  alias Conduit.Blog.Projections.{Article, Comment, FavoritedArticle, Feed}

  alias Conduit.Blog.Events.{
    ArticleCommented,
    ArticleFavorited,
    ArticlePublished,
    ArticleUnfavorited,
    CommentDeleted
  }

  alias Conduit.Repo

  project(%ArticlePublished{} = published, %{created_at: published_at}, fn multi ->
    multi
    |> Ecto.Multi.run(:author, fn _repo, _changes -> get_author(published.author_uuid) end)
    |> Ecto.Multi.run(:article, fn _repo, %{author: author} ->
      article = %Article{
        uuid: published.article_uuid,
        slug: published.slug,
        title: published.title,
        description: published.description,
        body: published.body,
        tag_list: published.tag_list,
        favorite_count: 0,
        published_at: published_at,
        author_uuid: author.uuid,
        author_username: author.username,
        author_bio: author.bio,
        author_image: author.image
      }

      Repo.insert(article)
    end)
    |> Ecto.Multi.run(:feed, fn _repo, %{author: author} ->
      feed = %Feed{
        article_uuid: published.article_uuid,
        author_uuid: author.uuid,
        published_at: published_at
      }

      for follower <- author.followers do
        Repo.insert(%Feed{feed | follower_uuid: follower})
      end

      {:ok, author}
    end)
  end)

  project(%ArticleCommented{} = commented, %{created_at: commented_at}, fn multi ->
    multi
    |> Ecto.Multi.run(:author, fn _repo, _changes -> get_author(commented.author_uuid) end)
    |> Ecto.Multi.run(:comment, fn _repo, %{author: author} ->
      comment = %Comment{
        uuid: commented.comment_uuid,
        body: commented.body,
        article_uuid: commented.article_uuid,
        author_uuid: author.uuid,
        author_username: author.username,
        author_bio: author.bio,
        author_image: author.image,
        commented_at: commented_at
      }

      Repo.insert(comment)
    end)
  end)

  project(%CommentDeleted{comment_uuid: comment_uuid}, fn multi ->
    Ecto.Multi.delete_all(multi, :comment, comment_query(comment_uuid))
  end)

  @doc """
  Favorite article for the user and update the article's favorite count
  """
  project(
    %ArticleFavorited{
      article_uuid: article_uuid,
      favorited_by_author_uuid: favorited_by_author_uuid,
      favorite_count: favorite_count
    },
    fn multi ->
      multi
      |> Ecto.Multi.run(:author, fn _repo, _changes -> get_author(favorited_by_author_uuid) end)
      |> Ecto.Multi.run(:favorited_article, fn _repo, %{author: author} ->
        favorite = %FavoritedArticle{
          article_uuid: article_uuid,
          favorited_by_author_uuid: favorited_by_author_uuid,
          favorited_by_username: author.username
        }

        Repo.insert(favorite)
      end)
      |> Ecto.Multi.update_all(:article, article_query(article_uuid),
        set: [favorite_count: favorite_count]
      )
    end
  )

  @doc """
  Delete the user's favorite and update the article's favorite count
  """
  project(
    %ArticleUnfavorited{
      article_uuid: article_uuid,
      unfavorited_by_author_uuid: unfavorited_by_author_uuid,
      favorite_count: favorite_count
    },
    fn multi ->
      multi
      |> Ecto.Multi.delete_all(
        :favorited_article,
        favorited_article_query(article_uuid, unfavorited_by_author_uuid)
      )
      |> Ecto.Multi.update_all(:article, article_query(article_uuid),
        set: [favorite_count: favorite_count]
      )
    end
  )

  defp get_author(uuid) do
    case Repo.get(Author, uuid) do
      nil -> {:error, :author_not_found}
      author -> {:ok, author}
    end
  end

  defp article_query(article_uuid) do
    from(a in Article, where: a.uuid == ^article_uuid)
  end

  defp comment_query(comment_uuid) do
    from(c in Comment, where: c.uuid == ^comment_uuid)
  end

  defp favorited_article_query(article_uuid, author_uuid) do
    from(f in FavoritedArticle,
      where: f.article_uuid == ^article_uuid and f.favorited_by_author_uuid == ^author_uuid
    )
  end
end
