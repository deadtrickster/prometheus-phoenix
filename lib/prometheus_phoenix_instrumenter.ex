defmodule Prometheus.PhoenixInstrumenter do
  import Phoenix.Controller
  require Logger

  use Prometheus.Config, [controller_call_labels: [:controller, :action],
                          duration_buckets: :prometheus_http.microseconds_duration_buckets(),
                          registry: :default]

  def setup do
    controller_call_labels = Config.controller_call_labels
    duration_buckets = Config.duration_buckets
    :prometheus_histogram.declare([name: :phoenix_controller_call_duration_microseconds,
                                   help: "Whole controller pipeline execution time.",
                                   labels: controller_call_labels,
                                   buckets: duration_buckets], Config.registry)
  end

  def phoenix_controller_call(:start, _compile, %{conn: conn}) do
    conn
  end
  def phoenix_controller_call(:stop, time_diff, conn) do
    labels = construct_labels(Config.controller_call_labels, conn)
    :prometheus_histogram.observe(Config.registry, :phoenix_controller_call_duration_microseconds,
      labels,
      microseconds_time(time_diff))
  end

  defp microseconds_time(time) do
    System.convert_time_unit(time, :native, :micro_seconds)
  end

  defp construct_labels(labels, data) do
    for label <- labels, do: label_value(label, data)
  end

  defp label_value(:controller, conn), do: inspect(controller_module(conn))
  defp label_value(:action, conn), do: action_name(conn)
  defp label_value(:method, conn), do: conn.method
  defp label_value(:host, conn), do: conn.host
  defp label_value(:scheme, conn), do: conn.scheme
  defp label_value(:port, conn), do: conn.port
  defp label_value({label, fun}, entry) when is_function(fun, 2), do: fun.(label, entry)
  defp label_value(fun, entry) when is_function(fun, 1), do: fun.(entry)
end
