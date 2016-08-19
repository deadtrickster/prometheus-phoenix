defmodule Prometheus.PhoenixInstrumenter.Config do

  @default_controller_call_labels [:controller, :action]
  @default_duration_buckets :prometheus_http.microseconds_duration_buckets()
  @default_config [controller_call_labels: @default_controller_call_labels,
                   duration_buckets: @default_duration_buckets]

  def controller_call_labels do
    config(:controller_call_labels, @default_controller_call_labels)
  end

  def duration_buckets do
    config(:duration_buckets, @default_duration_buckets)
  end

  def instrumenter_config do
    Application.get_env(:prometheus, PhoenixInstrumenter, @default_config)
  end

  def config(name, default) do
    instrumenter_config
    |> Keyword.get(name, default)
  end
  
end
