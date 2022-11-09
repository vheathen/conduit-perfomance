defmodule Conduit.Repo.Migrations.AddCounterToUsernames do
  use Ecto.Migration

  def change do
    alter table(:accounts_user_names) do
      add :counter, :integer, default: 0, null: false
    end

    create index(:accounts_user_names, [:counter])
  end
end
