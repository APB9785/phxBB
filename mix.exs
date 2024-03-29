defmodule PhxBb.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_bb,
      version: "0.8.2",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PhxBb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 2.3"},
      {:phoenix, "~> 1.6.5"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.7.1"},
      {:postgrex, "~> 0.15.13"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.17.5"},
      {:floki, ">= 0.32.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.6"},
      # Intentionally behind, will bump later
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.5"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18.2"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:tzdata, github: "lau/tzdata"},
      {:phoenix_html_sanitizer, github: "APB9785/phoenix_html_sanitizer"},
      {:earmark, "~> 1.4.19"},
      {:excoveralls, "~> 0.14.4", only: :test},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, github: "ex-aws/ex_aws_s3"},
      {:hackney, "~> 1.18"},
      {:sweet_xml, "~> 0.7.2"},
      {:mime, "~> 2.0", override: true},
      {:sobelow, "~> 0.11.1", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "cmd --cd assets npm run deploy",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
