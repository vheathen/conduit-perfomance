defmodule Conduit.Repo.Migrations.CreateConduit.Accounts.User do
  use Ecto.Migration

  def change do
    create table(:accounts_users, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :username, :string
      add :email, :string
      add :hashed_password, :string

      timestamps()
    end

    create unique_index(:accounts_users, [:username])
    create unique_index(:accounts_users, [:email])

    create index(:accounts_users, :inserted_at)
    create index(:accounts_users, :updated_at)
  end
end
