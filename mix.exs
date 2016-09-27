defmodule PrometheusPhoenix.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [app: :prometheus_phoenix,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: description,
     package: package,
     docs: [main: Prometheus.PhoenixInstrumenter,
            source_ref: "v#{@version}",
            source_url: "https://github.com/deadtrickster/prometheus-phoenix"]]
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
    [maintainers: ["Ilya Khaprov"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/deadtrickster/prometheus-phoenix",
              "Prometheus.erl" => "https://hex.pm/packages/prometheus",
              "Prometheus.ex" => "https://hex.pm/packages/prometheus_ex",
              "Plugs Instrumenter/Exporter" => "https://hex.pm/packages/prometheus_plugs",
              "Ecto Instrumenter" => "https://hex.pm/packages/prometheus_ecto",
              "Process info Collector" => "https://hex.pm/packages/prometheus_process_collector"}]
  end

  defp deps do
    [{:prometheus_ex, "~> 1.0.0"},
     {:phoenix, "~> 1.2"},    
     {:ex_doc, "~> 0.11", only: :dev},
     {:earmark, ">= 0.0.0", only: :dev}]
  end
end
