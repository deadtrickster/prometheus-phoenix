defmodule PrometheusPhoenix.Mixfile do
  use Mix.Project

  def project do
    [app: :prometheus_phoenix,
     version: "0.0.4",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: description,
     package: package]
  end

  def application do
    [applications: [:logger, :prometheus]]
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
              "Elixir Plugs" => "https://hex.pm/packages/prometheus_plugs",
              "Ecto Instrumenter" => "https://hex.pm/packages/prometheus_ecto"}]
  end

  defp deps do
    [{:prometheus, "~> 2.0"},
     {:phoenix, "~> 1.2"}]
  end
end
