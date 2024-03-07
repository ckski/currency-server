defmodule PaymentServer.ExchangeRate.Monitor do
  use GenServer

  require Logger

  alias PaymentServer.ExchangeRate
  alias PaymentServer.ExchangeRate.Endpoint
  alias PaymentServer.ExchangeRate.Cache

  @currencies Application.compile_env(:payment_server, :supported_currencies)
  @time_delay_ms Application.compile_env(:payment_server, :exchange_rate_update_frequency_ms, 1000)
  @use_default_publish Application.compile_env(:payment_server, :exchange_rate_use_default_publish_fn, true)

  @default_cache Cache
  @task_supervisor PaymentServer.ExchangeRate.TaskSupervisor

  @enforce_keys [:publish_fn]
  defstruct [:publish_fn, cache: nil, rates_monitored: %{}, tasks: %{}]

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)

    opts = if @use_default_publish do
      Keyword.put_new(opts, :publish_fn, &ExchangeRate.publish_new_rate/3)
    else
      Keyword.put_new(opts, :publish_fn, fn _,_,_ -> :ok end)
    end
    opts = Keyword.put_new(opts, :cache, @default_cache)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end
 
  @impl true
  def init(opts) do
    state = %__MODULE__{
      cache: opts[:cache],
      publish_fn: opts[:publish_fn]
    }

    opts
    |> Keyword.fetch!(:conversions)
    |> Enum.each(fn {from, to} ->
      schedule_rate_update({from, to})
      schedule_rate_update({to, from})
    end)

    {:ok, state}
  end

  @impl true
  def handle_info({:trigger_rate_update, {from_currency, to_currency}}, %{publish_fn: publish_fn, cache: cache} = state) do
    
    task = Task.Supervisor.async_nolink(@task_supervisor, fn -> 
      {:ok, rate} = ExchangeRate.fetch_and_update_rate(from_currency, to_currency, cache)
      publish_fn.(from_currency, to_currency, rate)

      :fetch_rate_done
    end)

    timestamp = :erlang.monotonic_time(:millisecond)
    state = put_in(state.tasks[task.ref], {from_currency, to_currency, timestamp})

    {:noreply, state}
  end

  def handle_info({ref, result}, state) do
    Process.demonitor(ref, [:flush])
    
    case result do
      :fetch_rate_done ->
        {{from_currency, to_currency, timestamp}, state} = pop_in(state.tasks[ref])
        
        # Schedule the next task to run based on when the task was created.
        time_elapsed_ms = :erlang.monotonic_time(:millisecond) - timestamp
        delay = max(0, @time_delay_ms - time_elapsed_ms)
        schedule_rate_update({from_currency, to_currency}, delay)

        {:noreply, state}
    end
  end

  defp do_start_monitoring_rate(state, from_currency, to_currency) do
    key = {from_currency, to_currency}
    schedule_rate_update({from_currency, to_currency})
  end

  defp schedule_rate_update(key, delay \\ @time_delay_ms) do
    Process.send_after(self(), {:trigger_rate_update, key}, delay)
  end
end