defmodule Conduit.Repo.Migrations.AddAnotherUserProjection do
  use Ecto.Migration

  def change do
    create table(:accounts_user_names, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :username, :string

      timestamps()
    end

    create index(:accounts_user_names, [:inserted_at])
    create index(:accounts_user_names, [:updated_at])
  end
end
