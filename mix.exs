defmodule PrometheusPhoenix.Mixfile do
  use Mix.Project

  @version "1.3.0"

  def project do
    [
      app: :prometheus_phoenix,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: [
        main: Prometheus.PhoenixInstrumenter,
        source_ref: "v#{@version}",
        source_url: "https://github.com/deadtrickster/prometheus-phoenix"
      ]
    ]
  end

  def application do
    [applications: [:logger, :prometheus_ex]]
  end

  defp description do
    """
    Prometheus monitoring system client Phoenix instrumenter.
    """
  end

  defp package do
    [
      maintainers: ["Ilya Khaprov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/deadtrickster/prometheus-phoenix",
        "Prometheus.erl" => "https://hex.pm/packages/prometheus",
        "Prometheus.ex" => "https://hex.pm/packages/prometheus_ex",
        "Plugs Instrumenter/Exporter" => "https://hex.pm/packages/prometheus_plugs",
        "Inets HTTPD Exporter" => "https://hex.pm/packages/prometheus_httpd",
        "Ecto Instrumenter" => "https://hex.pm/packages/prometheus_ecto",
        "Process info Collector" => "https://hex.pm/packages/prometheus_process_collector"
      }
    ]
  end

  defp deps do
    [
      {:prometheus_ex, "~> 1.3 or ~> 2.0 or ~> 3.0"},
      {:phoenix, "~> 1.4"},
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:phoenix_html, "~> 2.10", only: [:test]},
      {:ex_doc, "~> 0.16.1", only: [:dev]},
      {:earmark, "~> 1.2", only: [:dev]},
      {:credo, git: "https://github.com/rrrene/credo", only: [:dev, :test], runtime: false}
    ]
  end
end
