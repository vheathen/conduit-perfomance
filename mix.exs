defmodule Conduit.Mixfile do
  use Mix.Project

  def project do
    [
      app: :conduit,
      version: "0.0.1",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application() do
    [mod: {Conduit.Application, []}, extra_applications: [:eventstore]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:commanded, "~> 1.4"},
      {:commanded_ecto_projections, "~> 1.3"},
      {:commanded_eventstore_adapter, "~> 1.4"},
      {:eventstore, "~> 1.4"},
      {:cors_plug, "~> 3.0"},
      {:uniq, "~> 0.1"},
      {:elixir_uuid, "~> 0.1", hex: :uniq_compat, override: true},
      {:plug_cowboy, "~> 2.5"},
      {:exconstructor, "~> 1.2"},
      {:ex_machina, "~> 2.7", only: :test},
      {:gettext, "~> 0.20"},
      {:guardian, "~> 2.3"},
      {:jason, "~> 1.3"},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:postgrex, ">= 0.0.0"},
      {:slugger, "~> 0.3"},
      {:vex, "~> 0.9"}
    ]
  end

  defp aliases do
    [
      "event_store.init": ["event_store.drop", "event_store.create", "event_store.init"],
      "ecto.init": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      reset: ["event_store.init", "ecto.init"],
      test: ["reset", "test"]
    ]
  end
end
