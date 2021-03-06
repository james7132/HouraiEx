defmodule Hourai.Mixfile do
  use Mix.Project

  def project do
    [app: :hourai,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.detail": :test,
       "coveralls.post": :test,
       "coveralls.html": :test,
     ],
     aliases: aliases()]
  end

  # Applicationss as a part of the project
  def application do
    [
      extra_applications: [:logger],
      #applications: [:httpotion],
      mod: {Hourai, []}
    ]
  end

  # Dependencies
  defp deps do
    [
      {:nostrum, github: "Kraigie/nostrum", branch: "master"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.1"},
      {:ecto_enum, "~> 1.0"},
      {:httpotion, "~> 3.0.2"},
      {:timex, "~> 3.1"},
      {:timex_ecto, "~> 3.0"},
      {:excoveralls, "~> 0.7", only: :test}
    ]
  end

  defp aliases do
    [
      # This avoids running the actual full application when tests are run
      test: "test --no-start"
    ]
  end

end
