defmodule Conduit.Accounts.Projections.Username do
  use Ecto.Schema

  @primary_key {:uuid, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "accounts_user_names" do
    field(:username, :string)
    field(:counter, :integer, default: 0)

    timestamps()
  end
end
