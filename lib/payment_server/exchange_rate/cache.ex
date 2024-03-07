defmodule PaymentServer.ExchangeRate.Cache do
  use Task, restart: :permanent

  require Decimal
  import Decimal, only: [is_decimal: 1]

  @default_table_name __MODULE__
  @ets_opts [
    :named_table,
    :public,
    write_concurrency: true,
    read_concurrency: true
  ]

  def start_link(opts \\ []) do
    table_name = Keyword.get(opts, :name, @default_table_name)
    on_init = Keyword.get(opts, :on_init, fn -> :ok end)

    parent = self()

    Task.start_link(fn ->
      :ets.new(table_name, @ets_opts)
      on_init.()

      Process.hibernate(Function, :identity, [])
    end)
  end

  def put(key, value) do
    put(@default_table_name, key, value)
  end

  def put(nil, key, value) do
    put(@default_table_name, key, value)
  end

  def put(table, key, value) when is_binary(value) do
    put(table, key, Decimal.new(value))
  end

  def put(table, {from_currency, to_currency} = key, value)
    when is_binary(from_currency) and is_binary(to_currency) and is_decimal(value) do
    
    :ets.insert(table, {key, value})
  end

  def get(nil, key) do
    get(@default_table_name, key)
  end

  def get(table, {from_currency, to_currency} = key)
    when is_binary(from_currency) and is_binary(to_currency) do
    
    case :ets.lookup(table, key) do
      [] -> nil
      [{^key, value}] -> value
    end
  end
end