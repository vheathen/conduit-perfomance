defmodule Conduit.B do
  alias Conduit.Repo

  alias Conduit.Accounts
  alias Conduit.Accounts.Projections.User

  require Logger

  def create(amount \\ 100_000) do
    ts = System.monotonic_time(:millisecond)

    create_by_chunk(1..amount)

    te = System.monotonic_time(:millisecond)
    Logger.error("Time to create #{amount} users: #{te - ts}")
  end

  def create_in_parallel(amount \\ 5_000, chunk_length \\ 500) do
    ts = System.monotonic_time(:millisecond)

    1..amount
    |> Enum.chunk_every(chunk_length)
    |> Enum.map(&spawn_link(fn -> create_by_chunk(&1) end))

    te = System.monotonic_time(:millisecond)

    Logger.error(
      "Time to create #{amount} users by #{ceil(amount / chunk_length)} processes: #{te - ts}"
    )
  end

  def create_by_chunk(chunk) do
    ts = System.monotonic_time(:millisecond)

    for id <- chunk,
        str_id = Integer.to_string(id),
        padded_id = String.pad_leading(str_id, 7, "0"),
        username = "User-" <> padded_id,
        email = padded_id <> "@example.com",
        password = "1234",
        user_attrs = %{username: username, email: email, password: password},
        # _ = Logger.error(padded_id, label: "ID: "),
        {:ok, _uuid} = Accounts.register_user(user_attrs),
        id == Enum.at(chunk, 0) || rem(id, 100) == 0,
        do: Logger.error(username)

    te = System.monotonic_time(:millisecond)

    Logger.error("Time for a chunk: #{te - ts} ms")
  end

  def update_usernames_in_parallel(events_amount \\ 100_000) do
    users_to_update =
      User
      |> Repo.all()
      |> then(fn users -> Enum.take_random(users, round(length(users) * 0.7)) end)

    ts = System.monotonic_time(:millisecond)

    1..events_amount
    |> Enum.chunk_every(10_000)
    |> Enum.map(&spawn(fn -> update_username_by_chunk(&1, users_to_update) end))

    te = System.monotonic_time(:millisecond)

    Logger.error("Time to update usernames: #{te - ts} ms")
  end

  def update_username_by_chunk([first | _] = chunk, users) do
    ts = System.monotonic_time(:millisecond)
    Logger.error("Change for #{first}")

    for iteration <- chunk,
        user = Enum.random(users),
        new_username = UUID.uuid4(),
        :ok = Accounts.update_user(user, %{username: new_username, email: ""}),
        rem(iteration, 1_000) == 0,
        iteration = to_string(iteration),
        do: Logger.error(iteration)

    te = System.monotonic_time(:millisecond)
    Logger.error("Time for update a chunk: #{te - ts} ms")
  end
end
