defmodule PrometheusPhoenixTest do
  use ExUnit.Case
  use Phoenix.ConnTest

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
                       labels: ["PrometheusPhoenixTest.Controller", :qwe]])
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
                       labels: ["PrometheusPhoenixTest.Controller", :qwe_view]])
    assert (sum > 1_000_000 and sum < 1_200_000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)

    assert {buckets, sum} =
      Histogram.value([name: :phoenix_controller_render_duration_microseconds,
                       labels: [PrometheusPhoenixTest.View, "qwe_view.html", "html"]])
    assert (sum > 0 and sum < 100_000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end
end
