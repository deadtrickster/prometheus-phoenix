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
    assert {buckets, sum} = Histogram.value([name: :phoenix_controller_call_duration_microseconds,
                                             labels: ["PrometheusPhoenixTest.Controller", :qwe]])
    assert (sum > 1000000 and sum < 1200000)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end

  test "Custom config" do
    conn = get build_conn(), "/qwe"
    assert html_response(conn, 200) =~ "qwe"
    assert {buckets, sum} = Histogram.value([name: :phoenix_controller_call_duration_seconds,
                                             labels: ["PrometheusPhoenixTest.Controller", "custom_label"],
                                             registry: :qwe])
    assert (sum > 1 and sum < 1.2)
    assert 3 = length(buckets)
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end
end
