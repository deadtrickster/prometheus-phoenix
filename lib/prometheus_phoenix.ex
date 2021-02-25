defmodule PrometheusPhoenix do
  @moduledoc """
  TODO: Add the module docs
  """
  use Prometheus.Metric

  require Logger
  require Prometheus.Contrib.HTTP
  alias Prometheus.Contrib.HTTP

  @duration_unit :microseconds

  def setup do
    events = [
      [:phoenix, :endpoint, :stop],
      [:phoenix, :error_rendered],
      [:phoenix, :channel_joined],
      [:phoenix, :channel_handled_in]
    ]

    Logger.info("Attaching the phoenix telemetry events: #{inspect(events)}")

    :telemetry.attach_many(
      "telemetry_web__event_handler",
      events,
      &handle_event/4,
      nil
    )

    Histogram.declare(
      name: :"phoenix_controller_call_duration_#{@duration_unit}",
      help: "Whole controller pipeline execution time in #{@duration_unit}.",
      labels: [:action, :controller, :status],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )

    Histogram.declare(
      name: :"phoenix_controller_error_rendered_duration_#{@duration_unit}",
      help: "View error rendering time in #{@duration_unit}.",
      labels: [:action, :controller, :status],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )

    Histogram.declare(
      name: :"phoenix_channel_join_duration_#{@duration_unit}",
      help: "Phoenix channel join handler time in #{@duration_unit}",
      labels: [:channel, :topic, :transport],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )

    Histogram.declare(
      name: :"phoenix_channel_receive_duration_#{@duration_unit}",
      help: "Phoenix channel receive handler time in #{@duration_unit}",
      labels: [:channel, :topic, :transport, :event],
      buckets: HTTP.microseconds_duration_buckets(),
      duration_unit: @duration_unit,
      registry: :default
    )
  end

  def handle_event([:phoenix, :endpoint, :stop] = event, %{duration: duration}, metadata, _config) do
    with labels when is_list(labels) <- labels(metadata) do
      Logger.info("Recording the phoenix telemetry events: #{inspect(event)}")

      Histogram.observe(
        [
          name: :"phoenix_controller_call_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def handle_event([:phoenix, :error_rendered] = event, %{duration: duration}, metadata, _config) do
    with labels when is_list(labels) <- labels(metadata) do
      Logger.info("Recording the phoenix telemetry events: #{inspect(event)}")

      Histogram.observe(
        [
          name: :"phoenix_controller_error_rendered_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def handle_event([:phoenix, :channel_joined] = event, %{duration: duration}, metadata, _config) do
    with labels when is_list(labels) <- labels(metadata) do
      Logger.info("Recording the phoenix telemetry events: #{inspect(event)}")

      Histogram.observe(
        [
          name: :"phoenix_channel_join_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def handle_event(
        [:phoenix, :channel_handled_in] = event,
        %{duration: duration},
        metadata,
        _config
      ) do
    with labels when is_list(labels) <- labels(metadata) do
      Logger.info("Recording the phoenix telemetry events: #{inspect(event)}")

      Histogram.observe(
        [
          name: :"phoenix_channel_receive_duration_#{@duration_unit}",
          labels: labels,
          registry: :default
        ],
        duration
      )
    end
  end

  def labels(%{
        status: status,
        conn: %{private: %{phoenix_action: action, phoenix_controller: controller}}
      }) do
    [action, controller, status]
  end

  def labels(%{
        conn: %{
          status: status,
          private: %{phoenix_action: action, phoenix_controller: controller}
        }
      }) do
    [action, controller, status]
  end

  def labels(%{status: status, stacktrace: [{module, function, _, _} | _]}) do
    [function, module, status]
  end

  def labels(%{event: event, socket: %{channel: channel, topic: topic, transport: transport}}) do
    [channel, topic, transport, event]
  end

  def labels(%{socket: %{channel: channel, topic: topic, transport: transport}}) do
    [channel, topic, transport]
  end

  def labels(_metadata), do: nil
end
