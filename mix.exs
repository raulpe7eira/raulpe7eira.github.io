defmodule Site.MixProject do
  use Mix.Project

  def project do
    [
      app: :site,
      version: "0.1.0",
      elixir: "~> 1.20",
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ]
    ]
  end

  def application do
    [extra_applications: [:eex]]
  end

  defp deps do
    [
      {:chromic_pdf, "~> 1.17"},
      {:ecto, "~> 3.14"},
      {:gettext, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      precommit: [
        "compile --warnings-as-errors",
        "deps.unlock --check-unused",
        "gettext.extract --merge",
        "format",
        "credo",
        "deps.audit",
        "coveralls"
      ]
    ]
  end
end
