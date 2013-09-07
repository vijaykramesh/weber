defmodule Weber.Mixfile do
  use Mix.Project

  def project do
    [ app: :weber,
      version: "0.0.1",
      elixir: "~> 0.10.1-dev",
      deps: deps ]
  end

  def application do
    [
      applications: [:crypto, :ranch, :cowboy],
      description: "weber - is Elixir MVC web framework."
    ]
  end

  defp deps do
    [
      {:cowboy, "0.8.6", github: "extend/cowboy"}
    ]
  end
end
