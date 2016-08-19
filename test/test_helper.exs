ExUnit.start()

Application.put_env(:phoenix, Endpoint, [instrumenters: [Prometheus.PhoenixInstrumenter]])
defmodule Router do
  @moduledoc """
  Let's use a plug router to test this endpoint.
  """
  use Phoenix.Router

  get "/qwe", Controller, :qwe
end

defmodule Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix
  plug Router
end

defmodule Controller do
  use Phoenix.Controller

  def qwe(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "qwe")
  end
end
