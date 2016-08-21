defmodule Prometheus.PhoenixInstrumenter.Config do

  @default_controller_call_labels [:controller, :action]
  @default_duration_buckets :prometheus_http.microseconds_duration_buckets()
  @default_registry :default
  @default_config [controller_call_labels: @default_controller_call_labels,
                   duration_buckets: @default_duration_buckets,
                   registry: @default_registry]

  def controller_call_labels do
    config(:controller_call_labels, @default_controller_call_labels)
  end

  def duration_buckets do
    config(:duration_buckets, @default_duration_buckets)
  end

  def registry do
    config(:registry, @default_registry)
  end

  def config do
    Application.get_env(:prometheus, PhoenixInstrumenter, @default_config)
  end

  def config(name, default) do
    config
    |> Keyword.get(name, default)
  end
  
end
