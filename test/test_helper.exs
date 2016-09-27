ExUnit.start()

Application.put_env(:phoenix, PrometheusPhoenixTest.Endpoint,
  [instrumenters: [TestPhoenixInstrumenter,
                   TestPhoenixInstrumenterWithConfig]])

Application.put_env(:prometheus, TestPhoenixInstrumenterWithConfig,
  controller_call_labels: [:controller,
                           :custom_label],
  registry: :qwe,
  duration_buckets: [100, 200],
  duration_unit: :seconds)

defmodule TestPhoenixInstrumenter do
  use Prometheus.PhoenixInstrumenter
end

defmodule TestPhoenixInstrumenterWithConfig do
  use Prometheus.PhoenixInstrumenter

  def label_value(:custom_label, _) do
    "custom_label"
  end
end

defmodule PrometheusPhoenixTest.Router do
  use Phoenix.Router
  get "/qwe", PrometheusPhoenixTest.Controller, :qwe
end

defmodule PrometheusPhoenixTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix
  plug PrometheusPhoenixTest.Router
end

defmodule PrometheusPhoenixTest.Controller do
  use Phoenix.Controller

  def qwe(conn, _params) do
    Process.sleep(1000)
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "qwe")
  end
end

PrometheusPhoenixTest.Endpoint.start_link
