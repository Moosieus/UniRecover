defmodule UniRecover.MixProject do
  use Mix.Project

  @version "0.1.2"
  @source_url "https://github.com/Moosieus/UniRecover"

  def project do
    [
      app: :uni_recover,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "A native Elixir library for replacing illegal bytes in Unicode encoded data.",
      deps: deps(),
      docs: docs(),
      package: package(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps, do: [
    {:ex_doc, "~> 0.30.6", only: :dev, runtime: false},
    {:benchee, "~> 1.1.0", only: :dev, runtime: false},
  ]

  defp docs do
    [
      name: "UniRecover",
      main: "readme",
      source_ref: "main",
      source_url: @source_url,
      extras: [
        "README.md",
      ],
    ]
  end

  defp package do
    [
      name: "uni_recover",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
