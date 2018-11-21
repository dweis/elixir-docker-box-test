defmodule Box.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_docker_box_test,
      version: "0.1.0",
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:witchcraft, "~> 1.0"},
      {:algae, "~> 1.2"}
    ]
  end
end
