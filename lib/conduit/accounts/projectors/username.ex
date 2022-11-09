defmodule Conduit.Accounts.Projectors.Username do
  use Commanded.Projections.Ecto,
    application: Conduit.App,
    name: "Accounts.Projectors.Username",
    consistency: :eventual

  alias Conduit.Accounts.Events.{
    UsernameChanged,
    UserRegistered
  }

  alias Conduit.Accounts.Projections.Username

  project(%UserRegistered{} = registered, fn multi ->
    Ecto.Multi.insert(multi, :user, %Username{
      uuid: registered.user_uuid,
      username: registered.username
    })
  end)

  project(%UsernameChanged{user_uuid: user_uuid, username: username}, fn multi ->
    update_user(multi, user_uuid, username: username)
  end)

  defp update_user(multi, user_uuid, changes) do
    changes = Keyword.put(changes, :updated_at, DateTime.utc_now())

    Ecto.Multi.update_all(multi, :user, username_query(user_uuid), set: changes, inc: [counter: 1])
  end

  defp username_query(user_uuid) do
    from(un in Username, where: un.uuid == ^user_uuid)
  end
end
