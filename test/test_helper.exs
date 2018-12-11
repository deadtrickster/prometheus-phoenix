ExUnit.start()
:application.ensure_all_started(:plug)
:application.ensure_all_started(:phoenix)

Application.put_env(
  :phoenix,
  PrometheusPhoenixTest.Endpoint,
  instrumenters: [TestPhoenixInstrumenter, TestPhoenixInstrumenterWithConfig],
  pubsub: [name: SlackinEx.PubSub, adapter: Phoenix.PubSub.PG2]
)

Application.put_env(
  :prometheus,
  TestPhoenixInstrumenterWithConfig,
  controller_call_labels: [:controller, :custom_label],
  channel_join_labels: [:channel, :custom_channel_label],
  registry: :qwe,
  duration_buckets: [100, 200],
  duration_unit: :seconds
)

defmodule TestPhoenixInstrumenter do
  use Prometheus.PhoenixInstrumenter
end

defmodule TestPhoenixInstrumenterWithConfig do
  use Prometheus.PhoenixInstrumenter

  def label_value(:custom_label, _) do
    "custom_label"
  end

  def label_value(:custom_channel_label, _socket = %{topic: topic}) do
    "custom_channel:#{topic}"
  end
end

defmodule PrometheusPhoenixTest.Router do
  use Phoenix.Router
  get("/qwe", PrometheusPhoenixTest.Controller, :qwe)
  get("/qwe_view", PrometheusPhoenixTest.Controller, :qwe_view)
end

defmodule PrometheusPhoenixTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix

  socket("/socket", PrometheusPhoenixTest.TestSocket)

  plug(PrometheusPhoenixTest.Router)
end

defmodule PrometheusPhoenixTest.View do
  use Phoenix.View, root: "test/templates"
end

defmodule PrometheusPhoenixTest.Controller do
  use Phoenix.Controller

  def qwe(conn, _params) do
    Process.sleep(1000)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "qwe")
  end

  def qwe_view(conn, _params) do
    Process.sleep(1000)
    render(conn, PrometheusPhoenixTest.View, "qwe_view.html", name: "John Doe", layout: false)
  end
end

defmodule PrometheusPhoenixTest.TestSocket do
  use Phoenix.Socket

  channel("qwe:*", PrometheusPhoenixTest.TestChannel)

  transport(:websocket, Phoenix.Transports.WebSocket, timeout: 45_000)

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end

defmodule PrometheusPhoenixTest.TestChannel do
  use Phoenix.Channel

  def join("qwe:qwa", _payload, socket) do
    Process.sleep(200)
    {:ok, socket}
  end

  def handle_in("invite", payload, socket) do
    Process.sleep(500)
    {:reply, {:ok, payload}, socket}
  end
end

PrometheusPhoenixTest.Endpoint.start_link()
