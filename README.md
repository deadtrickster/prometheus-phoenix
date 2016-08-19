# PrometheusPhoenix [![Hex.pm](https://img.shields.io/hexpm/v/prometheus_phoenix.svg?maxAge=2592000)](https://hex.pm/packages/prometheus_phoenix) [![Build Status](https://travis-ci.org/deadtrickster/prometheus-phoenix.svg?branch=master)](https://travis-ci.org/deadtrickster/prometheus-phoenix)

## Metrics

 - `phoenix_controller_call_duration_microseconds` - Whole controller pipeline execution time.

    Labels:
    - `:controller`
    - `:action`
    - `:method`
    - `:scheme`
    - `:host`
    - `:port`

## Configuration

This integartion is configured via PhoenixInstrumenter :prometheus app env key

Default configuration:

``` elixir
config :prometheus, PhoenixInstrumenter,
  labels: [:controller, :action],
  duration_buckets: [10, 100, 1_000, 10_000, 100_000, 300_000,
                            500_000, 750_000, 1_000_000, 1_500_000,
                            2_000_000, 3_000_000]
```

Duration units are microseconds. You can find more on what stages are available and their description [here](https://hexdocs.pm/ecto/Ecto.LogEntry.html).

With this configuration scrape will look like this:

```
# TYPE phoenix_controller_call_duration_microseconds histogram
# HELP phoenix_controller_call_duration_microseconds Whole controller pipeline execution time.
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="10"} 0
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="100"} 0
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="1000"} 0
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="10000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="100000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="300000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="500000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="750000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="1000000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="1500000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="2000000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="3000000"} 1
phoenix_controller_call_duration_microseconds_bucket{controller="Controller1",action="index",le="+Inf"} 1
phoenix_controller_call_duration_microseconds_count{controller="Controller1",action="index"} 1
phoenix_controller_call_duration_microseconds_sum{controller="Controller1",action="index"} 7823
```

## Installation

[Available in Hex](https://hex.pm/packages/prometheus_phoenix/), the package can be installed as:

  1. Add `prometheus_phoenix` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:prometheus_phoenix, "~> 0.0.4"}]
    end
    ```

  2. Ensure `prometheus_phoenix` is started before your application:

    ```elixir
    def application do
      [applications: [:prometheus_phoenix]]
    end
    ```

