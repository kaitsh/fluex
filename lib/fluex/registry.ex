defmodule Fluex.Registry do
  @moduledoc false

  # TODO: Use persistent_term when depending on Erlang/OTP 22+
  use GenServer

  ## Public interface

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def associate(translator, value) do
    GenServer.call(__MODULE__, {:associate, translator, value})
  end

  def lookup(translator) when is_atom(translator) do
    :ets.lookup_element(__MODULE__, translator, 3)
  end

  ## Callbacks

  @impl true
  def init(:ok) do
    table = :ets.new(__MODULE__, [:named_table, read_concurrency: true])
    {:ok, table}
  end

  @impl true
  def handle_call({:associate, translator, value}, _from, table) do
    true = :ets.insert(table, {translator, value})
    {:reply, :ok, table}
  end

  @impl true
  def handle_info({:DOWN, ref, _type, translator, _reason}, table) do
    :ets.delete(table, translator)
    {:noreply, table}
  end
end
