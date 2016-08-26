ExUnit.start()

Application.put_env(:phoenix, PrometheusPhoenixTest.Endpoint,
  [instrumenters: [TestPhoenixInstrumenter]])

defmodule TestPhoenixInstrumenter do
  use Prometheus.PhoenixInstrumenter
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
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "qwe")
  end
end

TestPhoenixInstrumenter.setup()
PrometheusPhoenixTest.Endpoint.start_link
