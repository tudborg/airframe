defmodule Airframe.MixProject do
  use Mix.Project

  @version "0.1.1"

  @source_url "https://github.com/tudborg/airframe"

  def project do
    [
      app: :airframe,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      description: description(),
      package: package(),

      # docs
      name: "Airframe",
      docs: &docs/0
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Henrik Tudborg"],
      links: %{"GitHub" => @source_url},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp description() do
    """
    Airframe is an authorization library ala Bodyguard for use in your contexts.

    You write Policies. A Policy authorize (and narrow scope) on subjects and actions.
    """
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
