defmodule Coherence.Mixfile do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :coherence,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: [extras: ["README.md"], main: "Coherence"],
      deps: deps(),
      package: package(),
      dialyzer: [plt_add_apps: [:mix]],
      name: "Coherence",
      description: """
      A full featured, configurable authentication and user management system for Phoenix.
      """
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      mod: {Coherence, []},
      extra_applications: [
        :logger,
        :comeonin,
        :ecto_sql,
        :uuid,
        :phoenix_swoosh,
        :timex,
        :tzdata,
        :plug,
        :phoenix,
        :phoenix_html,
        :xmerl
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  defp deps do
    [
      {:postgrex, ">= 0.0.0", only: :test},
      {:ecto_sql, "~> 3.5.3"},
      {:comeonin, "~> 3.0"},
      {:phoenix, "~> 1.5.7"},
      {:phoenix_html, "~> 2.13"},
      {:gettext, "~> 0.14"},
      {:uuid, "~> 1.0"},
      {:phoenix_swoosh, "~> 0.2"},
      {:timex, "~> 3.6.3"},
      {:floki, "~> 0.8", only: :test},
      {:ex_doc, "~> 0.16", only: :dev},
      {:earmark, "~> 1.2", only: :dev, override: true},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:plug, "~> 1.10"},
      {:jason, "~> 1.0"}
    ]
  end

  defp package do
    [
      maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/smpallen99/coherence"},
      files: ~w(lib priv README.md mix.exs LICENSE)
    ]
  end
end
