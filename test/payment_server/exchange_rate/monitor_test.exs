defmodule PaymentServer.ExchangeRate.MonitorTest do
  use ExUnit.Case, async: false

  alias PaymentServer.ExchangeRate
  alias PaymentServer.ExchangeRate.Monitor
  alias PaymentServer.ExchangeRate.Cache

  @test_cache __MODULE__.TestCache

  setup_all :setup_cache

  def setup_cache(_context) do
    pid = self()
    on_init = fn ->
      send(pid, :cache_ready)
    end
    {:ok, _} = Cache.start_link(name: @test_cache, on_init: on_init)
    
    receive do
      :cache_ready ->
        ExchangeRate.set_initial_rate("CAD", "USD", "0.00", @test_cache)
        ExchangeRate.set_initial_rate("USD", "CAD", "0.00", @test_cache)        
        :ok
    end
  end

  @tag dev: true
  test "monitor server updates currency rates" do
    rate = ExchangeRate.get_latest_rate("CAD", "USD", @test_cache)
    assert Decimal.new("0.00") === rate

    rate = ExchangeRate.get_latest_rate("USD", "CAD", @test_cache)
    assert Decimal.new("0.00") === rate

    test_pid = self()

    {:ok, monitor} = Monitor.start_link(
      name: :test_monitor, 
      conversions: [{"CAD", "USD"}],
      cache: @test_cache,
      publish_fn: fn from,to,rate ->
        send(test_pid, {:publish, [from, to, rate]})
      end,
    )

    assert_receive {:publish, [_from, _to, _rate] = args}
    assert ["CAD", "USD", "1.51"] === args

    assert_receive {:publish, [_from, _to, _rate] = args}
    assert ["USD", "CAD", "0.98"] === args

    rate = ExchangeRate.get_latest_rate("CAD", "USD", @test_cache)
    assert Decimal.new("1.51") === rate

    rate = ExchangeRate.get_latest_rate("USD", "CAD", @test_cache)
    assert Decimal.new("0.98") === rate
  end
end