defmodule AsFsm.Mixfile do
  use Mix.Project

  def project do
    [
      app: :as_fsm,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "An Finite state machine implementation for elixir"
    ]
  end

  def package do
    [
      name: :as_fsm,
      files: ["lib", "mix.exs"],
      maintainers: ["Dung Nguyen"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/bluzky/as_fsm"}
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ ["test/support", "test/dummy"]
  defp elixirc_paths(_), do: elixirc_paths()
  defp elixirc_paths, do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
