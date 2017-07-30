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

  Currently controller_call and controller_render events are instrumented and exposed via `phoenix_controller_call_duration_<duration_unit>`
  and `phoenix_controller_render_duration_<duration_unit>` histograms. Channel metrics are coming soon.

  Default phoenix_controller_call labels:
   - controller - controller module name;
   - action - action name;
   - method - http method;
   - host - requested host;
   - port - requested port;
   - scheme - request scheme (like http or https).

  Default phoenix_controller_render labels:
   - view - name of the view;
   - template - name of the template;
   - format - name of the format of the template.

  ### Configuration

  Instrumenter configured via `:prometheus` application environment `MyApp.Endpoint.Instrumenter` key
  (i.e. app env key is the name of the instrumenter).

  Default configuration:

  ```elixir
  config :prometheus, MyApp.Endpoint.Instrumenter,
    controller_call_labels: [:controller, :action],
    duration_buckets: :prometheus_http.microseconds_duration_buckets(),
    registry: :default,
    duration_unit: :microseconds
  ```

  Available duration units:
   - microseconds;
   - milliseconds;
   - seconds;
   - minutes;
   - hours;
   - days.

  Bear in mind that buckets are ***<duration_unit>*** so if you are not using default unit
  you also have to override buckets.

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
  alias Prometheus.Contrib.HTTP

  use Prometheus.Config, [controller_call_labels: [:controller, :action],
                          controller_render_labels: [:view, :template, :format],
                          duration_buckets: HTTP.microseconds_duration_buckets(),
                          render_duration_buckets: HTTP.microseconds_duration_buckets(),
                          registry: :default,
                          duration_unit: :microseconds]

  use Prometheus.Metric

  ## support different endpoints via endpoint label
  defmacro __using__(_opts) do
    module_name = __CALLER__.module

    controller_call_labels = Config.controller_call_labels(module_name)
    ncontroller_call_labels = normalize_labels(controller_call_labels)
    duration_buckets = Config.duration_buckets(module_name)

    controller_render_labels = Config.controller_render_labels(module_name)
    ncontroller_render_labels = normalize_labels(controller_render_labels)
    render_duration_buckets = Config.duration_buckets(module_name)

    registry = Config.registry(module_name)
    duration_unit = Config.duration_unit(module_name)

    quote do

      import Phoenix.Controller
      use Prometheus.Metric

      def setup do
        Histogram.declare([name: unquote(:"phoenix_controller_call_duration_#{duration_unit}"),
                           help: unquote("Whole controller pipeline execution time in #{duration_unit}."),
                           labels: unquote(ncontroller_call_labels),
                           buckets: unquote(duration_buckets),
                           registry: unquote(registry)])
        Histogram.declare([name: unquote(:"phoenix_controller_render_duration_#{duration_unit}"),
                           help: unquote("View rendering time in #{duration_unit}."),
                           labels: unquote(ncontroller_render_labels),
                           buckets: unquote(render_duration_buckets),
                           registry: unquote(registry)])
      end

      def phoenix_controller_call(:start, _compile, %{conn: conn}) do
        conn
      end
      def phoenix_controller_call(:stop, time_diff, conn) do
        labels = unquote(construct_labels(controller_call_labels))
        Histogram.observe([registry: unquote(registry),
                           name: unquote(:"phoenix_controller_call_duration_#{duration_unit}"),
                           labels: labels], time_diff)
      end

      def phoenix_controller_render(:start, _compile, data) do
        data
      end
      def phoenix_controller_render(:stop, time_diff, %{view: view, template: template, format: format, conn: conn}) do
        labels = unquote(construct_labels(controller_render_labels))
        Histogram.observe([registry: unquote(registry),
                           name: unquote(:"phoenix_controller_render_duration_#{duration_unit}"),
                           labels: labels], time_diff)
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
  defp label_value(:view) do
    quote do
      view
    end
  end
  defp label_value(:template) do
    quote do
      template
    end
  end
  defp label_value(:format) do
    quote do
      format
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
