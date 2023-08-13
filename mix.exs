defmodule UniRecover.MixProject do
  use Mix.Project

  def project do
    [
      app: :uni_recover,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "A native Elixir library for replacing illegal bytes in Unicode encoded data.",
      deps: deps(),
      package: [
        name: "uni_recover",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/Moosieus/UniRecover"}
      ],
      docs: [
        name: "UniRecover",
        main: "readme",
        source_ref: "main",
        source_url: "https://github.com/Moosieus/elixir-a2s",
        extras: [
          "README.md"
        ],
      ],
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
    {:ex_doc, "~> 0.30.5", only: :dev, runtime: false}
  ]
end
