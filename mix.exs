defmodule Coherence.Mixfile do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :coherence,
      version: @version,
      elixir: "~> 1.17.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
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
        :elixir_uuid,
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
      {:ecto_sql, "~> 3.12.0"},
      {:comeonin, "~> 3.0"},
      {:phoenix, "~> 1.6.10"},
      {:phoenix_html, "~> 2.2"},
      {:gettext, "~> 0.26.1"},
      {:elixir_uuid, "~> 1.2"},
      {:phoenix_swoosh, "~> 0.3.2"},
      {:timex, "~> 3.7.11"},
      {:floki, "~> 0.26.0", only: :test},
      {:ex_doc, "~> 0.19", only: :dev},
      {:earmark, "~> 1.2", only: :dev, override: true},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 1.5.6", only: [:dev, :test]},
      {:plug, "~> 1.14.0"},
      {:jason, "~> 1.2"},
      {:bcrypt_elixir, "~> 0.12.1"},
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
