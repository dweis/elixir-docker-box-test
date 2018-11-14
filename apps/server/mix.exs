defmodule Server.MixProject do
  use Mix.Project

  def project do
    [
      app: :server,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Server.Application, []},
      applications: [:plug_cowboy, :poison]
    ]
  end

  defp deps do
    [
      {:distillery, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"}
    ]
  end
end
