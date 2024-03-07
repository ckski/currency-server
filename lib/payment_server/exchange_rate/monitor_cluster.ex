defmodule PaymentServer.ExchangeRate.MonitorCluster do
  use Supervisor

  alias PaymentServer.ExchangeRate.Monitor

  @currencies Application.compile_env(:payment_server, :supported_currencies)
  @num_conversions_handled_per_monitor 250

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do  
    children =
      @currencies
      |> get_combinations
      |> Enum.chunk_every(@num_conversions_handled_per_monitor)
      |> Enum.with_index
      |> Enum.map(fn {conversions, index} ->
        name = String.to_atom("monitor_#{index}")
        Supervisor.child_spec({Monitor, [name: name, conversions: conversions]}, id: name)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_combinations([]), do: []
  defp get_combinations([element | tail]) do
    generate_combinations(element, tail) ++ get_combinations(tail)
  end
  defp generate_combinations(first_element, list) do
    for second_element <- list, do: {first_element, second_element}
  end
end