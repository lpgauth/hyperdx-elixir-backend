defmodule Hyperdx.MixProject do
  use Mix.Project

  def project do
    [
      app: :hyperdx,
      version: "0.1.6",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      organization: "HyperDX",
      source_url: "https://github.com/hyperdxio/hyperdx-elixir-backend",
      homepage_url: "https://hyperdx.io",
      name: "HyperDX",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:buoy, git: "https://github.com/lpgauth/buoy.git", tag: "0.2.4"},
      {:metal, "0.1.1", [env: :prod, hex: "metal", override: true, repo: "hexpm"]},
      {:jason, "~> 1.0"}
    ]
  end

  defp description do
    "Elixir logging backend that sends your logs to HyperDX using the https bulk API"
  end

  defp package do
    [
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/hyperdxio/hyperdx-elixir-backend"}
    ]
  end
end
