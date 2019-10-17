defmodule Fluex.MixProject do
  use Mix.Project

  def project do
    [
      app: :fluex,
      version: "0.0.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [
        fluex_rs: [
          mode: if(Mix.env() == :prod, do: :release, else: :debug)
        ]
      ],
      description: "fluent-rs NIF localization/translation for Elixir",
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Kaitsh <kaitsh@d-git.de"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/kaitsh/fluex"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Fluex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:rustler, "~> 0.21.0"}
    ]
  end
end
