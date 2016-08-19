defmodule Prometheus.PhoenixInstrumenter do
  import Phoenix.Controller
  require Logger

  alias Prometheus.PhoenixInstrumenter.Config

  def setup do
    controller_call_labels = Config.controller_call_labels

    :prometheus_histogram.declare([name: :phoenix_controller_call_duration_microseconds,
                                   help: "Whole controller pipeline execution time.",
                                   labels: controller_call_labels,
                                   buckets: Config.duration_buckets])
  end

  def phoenix_controller_call(:start, _compile, %{conn: conn}) do
    conn
  end
  def phoenix_controller_call(:stop, time_diff, conn) do
    IO.puts(conn)
    labels = construct_labels(Config.controller_call_labels, conn)
    :prometheus_histogram.observe(:phoenix_controller_call_duration_microseconds,
      labels,
      microseconds_time(time_diff))
  end
  
  defp microseconds_time(time) do
    System.convert_time_unit(time, :native, :micro_seconds)
  end  

  defp construct_labels(labels, data) do
    for label <- labels, do: label_value(label, data)
  end
  
  defp label_value(:controller, conn) do
    inspect(controller_module(conn))
  end
  defp label_value(:action, conn) do
    action_name(conn)
  end
  
  defp label_value({label, fun}, entry) when is_function(fun, 2), do: fun.(label, entry)
  defp label_value(fun, entry) when is_function(fun, 1), do: fun.(entry)
end
