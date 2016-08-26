defmodule Prometheus.PhoenixInstrumenter do
  @moduledoc """

  Phoenix instrumenter generator for Prometheus. Implemented as Phoenix instrumenter.

  ### Usage

  1. Define your instrumenter:

  ```elixir
  defmodule MyApp.Endpoint.Instrumenter do
    use Prometheus.PhoenixInstrumenter
  end
  ```

  2. Call `MyApp.Endpoint.Instrumenter.setup/0` when application starts (e.g. supervisor setup):

  ```elixir
  MyApp.Endpoint.Instrumenter.setup()
  ```

  3. Add `MyApp.Endpoint.Instrumenter` to Phoenix endpoint instrumenters list:

  ```elixir
  config :myapp, MyApp.Endpoint,
    ...
    instrumenters: [MyApp.Endpoint.Instrumenter]
    ...

  ```

  ### Metrics

  Currently only one controller_call event is instrumented and exposed via `phoenix_controller_call_duration_microseconds`
  histogram. Render_view is coming soon (awaits phoenix release).

  Default labels:
   - controller - controller module name;
   - action - action name;
   - method - http method;
   - host - requested host;
   - port - requested port;
   - scheme - request scheme (like http or https).

  ### Configuration

  Instrumenter configured via `:prometheus` application environment `MyApp.Endpoint.Instrumenter` key
  (i.e. app env key is the name of the instrumenter).

  Default configuration:

  ```elixir
  config :prometheus, MyApp.Endpoint.Instrumenter,
    controller_call_labels: [:controller, :action],
    duration_buckets: :prometheus_http.microseconds_duration_buckets(),
    registry: :default
  ```

  Bear in mind that bounds are ***microseconds*** (1s is 1_000_000us)

  ### Custom Labels

  Custom labels can be defined by implementing label_value/2 function in instrumenter directly or
  by calling exported function from other module.

  ```elixir
    controller_call_labels: [:controller,
                             :my_private_label,
                             {:label_from_other_module, Module}, # eqv to {Module, label_value}
                             {:non_default_label_value, {Module, custom_fun}}]


  defmodule MyApp.Endpoint.Instrumenter do
    use Prometheus.PhoenixInstrumenter

    label_value(:my_private_label, conn) do
      ...
    end
  end
  ```
  """

  import Phoenix.Controller
  require Logger
  require Prometheus.Contrib.HTTP

  use Prometheus.Config, [controller_call_labels: [:controller, :action],
                          duration_buckets: Prometheus.Contrib.HTTP.microseconds_duration_buckets(),
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
