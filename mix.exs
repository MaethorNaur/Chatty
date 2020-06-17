defmodule Chatty.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatty,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [
          "-Wunmatched_returns",
          "-Werror_handling",
          "-Wrace_conditions",
          "-Wno_opaque",
          "-Wunderspecs"
        ],
        plt_add_deps: :transitive
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Chatty.Application, [Mix.env()]}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.10"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.0"},
      {:libcluster, "~> 3.2"},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
