defmodule Airframe.MixProject do
  use Mix.Project

  def project do
    [
      app: :airframe,
      version: "0.1.1",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Docs
      name: "Airframe",
      source_url: "https://github.com/tudborg/airframe",
      homepage_url: nil,
      docs: &docs/0
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    []
  end

  defp deps do
    [
      {:ecto, "~> 3.10", optional: true},

      # docs
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
