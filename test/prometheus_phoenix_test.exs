defmodule PrometheusPhoenixTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  use Phoenix.ChannelTest

  use Prometheus.Metric
  require Prometheus.Registry

  @endpoint PrometheusPhoenixTest.Endpoint

  setup do
    Prometheus.Registry.clear(:default)
    Prometheus.Registry.clear(:qwe)
    TestPhoenixInstrumenter.setup()
    TestPhoenixInstrumenterWithConfig.setup()
    :ok
  end

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "Default config" do
    conn = get build_conn(), "/qwe"
    assert html_response(conn, 200) =~ "qwe"
    assert {buckets, sum} =
      Histogram.value([name: :phoenix_controller_call_duration_microseconds,
                       labels: [:qwe, "PrometheusPhoenixTest.Controller"]])
    assert (sum > 1_000_000 and sum < 1_200_000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end

  test "Custom config" do
    conn = get build_conn(), "/qwe"
    assert html_response(conn, 200) =~ "qwe"
    assert {buckets, sum} =
      Histogram.value([name: :phoenix_controller_call_duration_seconds,
                       labels: ["PrometheusPhoenixTest.Controller", "custom_label"],
                       registry: :qwe])
    assert (sum > 1 and sum < 1.2)
    assert 3 = length(buckets)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end

  test "Default config view" do
    conn = get build_conn(), "/qwe_view"
    assert html_response(conn, 200) =~ "Hello John Doe"
    assert {buckets, sum} =
      Histogram.value([name: :phoenix_controller_call_duration_microseconds,
                       labels: [:qwe_view, "PrometheusPhoenixTest.Controller"]])
    assert (sum > 1_000_000 and sum < 1_200_000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)

    assert {buckets, sum} =
      Histogram.value([name: :phoenix_controller_render_duration_microseconds,
                       labels: ["html", "qwe_view.html", PrometheusPhoenixTest.View]])
    assert (sum > 0 and sum < 100_000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end

  test "Channel join/receive" do
    socket = socket()
    socket = %{socket | vsn: "2.0.0"}
    {:ok, _, socket} = socket
    |> subscribe_and_join(PrometheusPhoenixTest.TestChannel, "qwe:qwa")
    ref = push socket, "invite", %{"user" => "John"}
    assert_reply ref, :ok,  %{"user" => "John"}, 1000

    assert {buckets, sum} =
      Histogram.value([name: :phoenix_channel_join_duration_microseconds,
                       labels: ["PrometheusPhoenixTest.TestChannel", "qwe:qwa", "channel_test", "2.0.0"]])
    assert (sum > 200_000 and sum < 300_000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)

    assert {buckets, sum} =
      Histogram.value([name: :phoenix_channel_receive_duration_microseconds,
                       labels: ["PrometheusPhoenixTest.TestChannel", "qwe:qwa", "channel_test", "2.0.0", "invite"]])
    assert (sum > 500_000 and sum < 600_000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end
end
