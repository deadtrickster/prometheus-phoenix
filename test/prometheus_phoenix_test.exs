defmodule PrometheusPhoenixTest do
  use ExUnit.Case
  use Phoenix.ConnTest

  @endpoint Endpoint

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "Qwe" do
    Endpoint.start_link
    Prometheus.PhoenixInstrumenter.setup()
    conn = get conn(), "/qwe"
    assert html_response(conn, 200) =~ "qwe"
    assert {buckets, sum} = :prometheus_histogram.value(:phoenix_controller_call_duration_microseconds, ["Controller", :qwe])
    assert sum > 0
    assert 1 = Enum.reduce(buckets, fn(x, acc) -> x + acc end)
  end
end
