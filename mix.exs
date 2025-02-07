defmodule SimpleSearch.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_search,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      included_applications: [:mnesia]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "fixtures"]
  defp elixirc_paths(:test), do: ["lib", "fixtures"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stemmer, git: "https://github.com/fredwu/stemmer.git", tag: "v1.2.0"},
      {:trieval, "~> 1.1"}
    ]
  end
end
