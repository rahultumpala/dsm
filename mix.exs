defmodule Dsm.MixProject do
  use Mix.Project

  @source_url "https://github.com/rahultumpala/dsm"
  @version "0.1.0"

  def project do
    [
      app: :dsm,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "dsm is a zero dependency, compile-time abstraction library that helps you define Finite State Machines in a declarative manner."
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
      ],
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: [
        "CHANGELOG.md"
      ]
    ]
  end

    defp package() do
    [
      licenses: ["MIT"],
      maintainers: ["Rahul Tumpala"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/iris/changelog.html",
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
