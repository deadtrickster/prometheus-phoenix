defmodule Prometheus.PhoenixInstrumenter do
  import Phoenix.Controller
  require Logger

  use Prometheus.Config, [controller_call_labels: [:controller, :action],
                          duration_buckets: :prometheus_http.microseconds_duration_buckets(),
                          registry: :default]

  use Prometheus.Metric

  ## support different endpoints via endpoint label
  defmacro __using__(_opts) do
    module_name = __CALLER__.module

    controller_call_labels = Config.controller_call_labels(module_name)
    ncontroller_call_labels = normalize_labels(controller_call_labels)
    duration_buckets = Config.duration_buckets(module_name)
    registry = Config.registry(module_name)
    
    quote do
      
      import Phoenix.Controller
      use Prometheus.Metric
      
      def setup do
        Histogram.declare([name: :phoenix_controller_call_duration_microseconds,
                           help: "Whole controller pipeline execution time.",
                           labels: unquote(ncontroller_call_labels),
                           buckets: unquote(duration_buckets),
                           registry: unquote(registry)])
      end

      def phoenix_controller_call(:start, _compile, %{conn: conn}) do
        conn
      end
      def phoenix_controller_call(:stop, time_diff, conn) do
        labels = unquote(construct_labels(controller_call_labels))
        Histogram.observe([registry: unquote(registry),
                           name: :phoenix_controller_call_duration_microseconds,
                           labels: labels], microseconds_time(time_diff))
      end

      defp microseconds_time(time) do
        System.convert_time_unit(time, :native, :micro_seconds)
      end
    end
  end  

  defp normalize_labels(labels) do
    for label <- labels do
      case label do
        {name, _} -> name
        name -> name
      end
    end
  end

  defp construct_labels(labels) do
    for label <- labels, do: label_value(label)
  end

  defp label_value(:controller) do
    quote do
      inspect(controller_module(conn))
    end
  end
  defp label_value(:action) do
    quote do
      action_name(conn)
    end
  end
  defp label_value(:method) do
    quote do
      conn.method
    end
  end
  defp label_value(:host) do
    quote do
      conn.host
    end
  end
  defp label_value(:scheme) do
    quote do
      conn.scheme
    end
  end
  defp label_value(:port) do
    quote do
      conn.port
    end
  end
  defp label_value({label, {module, fun}}) do
    quote do
      unquote(module).unquote(fun)(unquote(label), conn)
    end
  end
  defp label_value({label, module}) do
    quote do
      unquote(module).label_value(unquote(label), conn)
    end
  end
  defp label_value(label) do
    quote do
      label_value(unquote(label), conn)
    end
  end
end
