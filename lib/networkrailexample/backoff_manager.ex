defmodule NetworkRailExample.BackoffManager do
  @moduledoc """
  Basic exponential backoff manager
  """

  use GenServer

  # 10min ceiling
  @backoff_limit_millis 600_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  defp ensure_member(state, connection_id) do
    Map.put_new(state, connection_id, 0)
  end

  def handle_call({:get_interval, connection_id}, _from, state) do
    {:reply, Map.get(state, connection_id) || 0, ensure_member(state, connection_id)}
  end

  def handle_call({:connect_failed, connection_id}, _from, state) do
    {:reply, :ok,
     Map.update(state, connection_id, 0, fn duration ->
       Kernel.min(Kernel.max(duration, 2000) * 2, @backoff_limit_millis)
     end)}
  end

  def handle_call({:connect_success, connection_id}, _from, state) do
    {:reply, :ok, Map.update(state, connection_id, 0, fn _ -> 0 end)}
  end

  def get_interval(connection_id) do
    GenServer.call(__MODULE__, {:get_interval, connection_id})
  end

  def notify_failure(connection_id) do
    GenServer.call(__MODULE__, {:connect_failed, connection_id})
  end

  def notify_success(connection_id) do
    GenServer.call(__MODULE__, {:connect_success, connection_id})
  end
end
