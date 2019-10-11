defmodule HttpServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :http_server,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug],
      mod: {HttpServer.Application, [Mix.env()]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.8"},
      {:cowboy, "~> 2.6"},
      {:plug_cowboy, "~> 2.1"}
    ]
  end
end
