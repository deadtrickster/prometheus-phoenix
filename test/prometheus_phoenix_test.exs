defmodule PrometheusPhoenixTest do
  use PrometheusPhoenixTestWeb.ConnCase
  use PrometheusPhoenixTestWeb.ChannelCase

  import ExUnit.CaptureLog, only: [capture_log: 1]

  require Prometheus.Metric.Histogram
  require Prometheus.Registry
  require Logger

  alias Prometheus.Metric.Histogram

  describe "Channel tests" do
    test "joining a channel" do
      socket = socket(PrometheusPhoenixTestWeb.TestSocket)

      assert {:ok, _payload, socket} =
               subscribe_and_join(socket, PrometheusPhoenixTestWeb.TestChannel, "qwe:qwa")

      assert {buckets, sum} =
               Histogram.value(
                 name: :phoenix_channel_join_duration_microseconds,
                 labels: [PrometheusPhoenixTestWeb.TestChannel, "qwe:qwa", :channel_test]
               )

      assert sum > 200_000 and sum < 300_000
      assert 1 = Enum.reduce(buckets, fn x, acc -> x + acc end)

      assert ref = Phoenix.ChannelTest.push(socket, "invite", %{"name" => "Bob Dobbs"})
      assert_reply(ref, :ok, %{"name" => "Bob Dobbs"}, 1000)

      assert {buckets, sum} =
               Histogram.value(
                 name: :phoenix_channel_receive_duration_microseconds,
                 labels: [
                   PrometheusPhoenixTestWeb.TestChannel,
                   "qwe:qwa",
                   :channel_test,
                   "invite"
                 ]
               )

      assert sum > 500_000 and sum < 600_000
      assert 1 = Enum.reduce(buckets, fn x, acc -> x + acc end)
    end
  end

  describe "Controller tests" do
    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Welcome to PrometheusPhoenix!"

      assert {buckets, sum} =
               Histogram.value(
                 name: :phoenix_controller_call_duration_microseconds,
                 labels: [:index, PrometheusPhoenixTestWeb.PageController, 200]
               )

      assert sum > 1_000_000 and sum < 1_200_000
      assert 1 = Enum.reduce(buckets, fn x, acc -> x + acc end)
    end

    test "GET /error-422", %{conn: conn} do
      conn = get(conn, "/error-422")
      assert html_response(conn, 422) =~ "Bad Request"

      assert {buckets, sum} =
               Histogram.value(
                 name: :phoenix_controller_call_duration_microseconds,
                 labels: [:error, PrometheusPhoenixTestWeb.PageController, 422]
               )

      assert sum > 1_000_000 and sum < 1_200_000
      assert 1 = Enum.reduce(buckets, fn x, acc -> x + acc end)
    end

    test "GET /raise-error", %{conn: conn} do
      assert capture_log(fn ->
               try do
                 get(conn, "/raise-error")
               rescue
                 _e in RuntimeError ->
                   Logger.error("Internal Server Error")
               end
             end) =~ "Internal Server Error"

      assert {buckets, sum} =
               Histogram.value(
                 name: :phoenix_controller_call_duration_microseconds,
                 labels: [:raise_error, PrometheusPhoenixTestWeb.PageController, 500]
               )

      assert sum > 1_000_000 and sum < 1_200_000
      assert 1 = Enum.reduce(buckets, fn x, acc -> x + acc end)

      assert {buckets, sum} =
               Histogram.value(
                 name: :phoenix_controller_error_rendered_duration_microseconds,
                 labels: [:raise_error, PrometheusPhoenixTestWeb.PageController, 500]
               )

      assert sum > 1 and sum < 5_000
      assert 1 = Enum.reduce(buckets, fn x, acc -> x + acc end)
    end
  end
end
