defmodule Dankie.MixProject do
  use Mix.Project

  def project do
    [
      app: :dankie,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Dankie.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.12.1"},
      {:finch, "~> 0.14.0"},
      {:jason, ">= 1.0.0"},
      {:plug, "~> 1.16"},
      {:ex_gram, "~> 0.53"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
