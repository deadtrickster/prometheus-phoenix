defmodule PrometheusPhoenixTestWeb.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller

  scope "/", PrometheusPhoenixTestWeb do
    get("/", PageController, :index)
    get("/error-422", PageController, :error)
    get("/raise-error", PageController, :raise_error)
  end
end

defmodule PrometheusPhoenixTestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :prometheus_phx_test

  socket("/socket", PrometheusPhoenixTestWeb.TestSocket,
    websocket: true,
    longpoll: false
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
  plug(PrometheusPhoenixTestWeb.Router)
end

defmodule PrometheusPhoenixTestWeb.TestSocket do
  use Phoenix.Socket

  channel("qwe:*", PrometheusPhoenixTestWeb.TestChannel)

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end

defmodule PrometheusPhoenixTestWeb.TestChannel do
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

defmodule PrometheusPhoenixTestWeb.PageController do
  use Phoenix.Controller, namespace: PrometheusPhoenixTestWeb

  def index(conn, _params) do
    Process.sleep(1000)
    render(conn, "index.html")
  end

  def error(conn, _params) do
    Process.sleep(1000)

    conn
    |> put_status(422)
    |> put_view(PrometheusPhoenixTestWeb.ErrorView)
    |> render("422.html")
  end

  def raise_error(_conn, _params) do
    Process.sleep(1000)
    raise "Internal Server Error"
  end
end

defmodule PrometheusPhoenixTestWeb.PageView do
  use Phoenix.View,
    root: "test/support/templates"
end

defmodule PrometheusPhoenixTestWeb.LayoutView do
  use Phoenix.View,
    root: "test/support/templates"
end

defmodule PrometheusPhoenixTestWeb.ErrorView do
  use Phoenix.View,
    root: "test/support/templates"

  def render("404.html", _assigns), do: "Not Found"
  def render("422.html", _assigns), do: "Bad Request"
  def render("500.html", _assigns), do: "Internal Server Error"
end

defmodule PrometheusPhoenixTest.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: PrometheusPhoenixTest.PubSub},
      PrometheusPhoenixTestWeb.Endpoint
    ]

    PrometheusPhoenix.setup()

    opts = [strategy: :one_for_one, name: PrometheusPhoenixTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
