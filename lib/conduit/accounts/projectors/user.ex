defmodule Conduit.Accounts.Projectors.User do
  use Commanded.Projections.Ecto,
    application: Conduit.App,
    name: "Accounts.Projectors.User"

  # consistency: :strong

  alias Conduit.Accounts.Events.{
    UserEmailChanged,
    UsernameChanged,
    UserPasswordChanged,
    UserRegistered
  }

  alias Conduit.Accounts.Projections.User

  project(%UserRegistered{} = registered, fn multi ->
    Ecto.Multi.insert(multi, :user, %User{
      uuid: registered.user_uuid,
      username: registered.username,
      email: registered.email,
      hashed_password: registered.hashed_password
    })
  end)

  project(%UsernameChanged{user_uuid: user_uuid, username: username}, fn multi ->
    update_user(multi, user_uuid, username: username)
  end)

  project(%UserEmailChanged{user_uuid: user_uuid, email: email}, fn multi ->
    update_user(multi, user_uuid, email: email)
  end)

  project(
    %UserPasswordChanged{user_uuid: user_uuid, hashed_password: hashed_password},
    fn multi ->
      update_user(multi, user_uuid, hashed_password: hashed_password)
    end
  )

  defp update_user(multi, user_uuid, changes) do
    changes = Keyword.put(changes, :updated_at, DateTime.utc_now())
    Ecto.Multi.update_all(multi, :user, user_query(user_uuid), set: changes)
  end

  defp user_query(user_uuid) do
    from(u in User, where: u.uuid == ^user_uuid)
  end
end
