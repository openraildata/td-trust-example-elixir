defmodule NetworkRailExample.CallbackHandler do
  use GenServer
  alias NetworkRailExample.BackoffManager
  require Logger

  alias NetworkRailExample.Util

  alias Barytherium.Frame
  alias Barytherium.Network
  alias Barytherium.Network.Sender

  def start_link(
        [id: id, host: host, port: port, user: user, pass: pass, queue: queue],
        link_opts \\ []
      ) do
    GenServer.start_link(
      __MODULE__,
      %{
        id: id,
        host: host,
        port: port,
        user: user,
        pass: pass,
        queue: queue
      },
      link_opts
    )
  end

  def init(state = %{id: id, host: _host, port: _port, user: _user, pass: _pass}) do
    interval = BackoffManager.get_interval(id)
    Logger.info("#{id} waiting before attempting (re)connection #{interval}ms")
    Process.send_after(self(), :connect, interval)
    state = Map.put(state, :connected, false)
    {:ok, state}
  end

  def handle_info(:connect, state = %{host: host, port: port}) do
    {:ok, network_pid} = Network.start_link(self(), host, port)

    {:noreply, Map.put(state, :network_pid, network_pid)}
  end

  def handle_cast(
        {:barytherium, :connect, {:error, error}},
        state = %{host: host, port: port, id: id}
      ) do
    Logger.error("Connection to #{host}:#{port} failed, error: #{error}")
    BackoffManager.notify_failure(id)
    {:stop, :connect_error, state}
  end

  def handle_cast(
        {:barytherium, :connect, {:ok, sender_pid}},
        state = %{
          id: id,
          user: user,
          pass: pass,
          host: host,
          port: port
        }
      ) do
    Logger.info("Connection to #{host}:#{port} succeeded, remote end has picked up")
    BackoffManager.notify_success(id)

    Sender.write(sender_pid, [
      %Frame{
        command: :connect,
        headers: [
          {"accept-version", "1.2"},
          {"host", "/"},
          {"heart-beat", "7000,7000"},
          {"login", user},
          {"passcode", pass},
          {"client-id", "#{user}-td-trust-test"}
        ]
      }
    ])

    {:noreply, state}
  end

  def handle_cast(
        {:barytherium, :frames, {[frame = %Frame{command: :connected}], sender_pid}},
        state = %{user: user, queue: queue}
      ) do
    Logger.info("Received connected frame: " <> inspect(frame, binaries: :as_strings))

    Sender.write(sender_pid, [
      %Frame{
        command: :subscribe,
        headers: [
          {"id", "0"},
          {"destination", queue},
          {"ack", "client"},
          {"activemq.subscriptionName", "#{user}-#{queue}"}
        ]
      }
    ])

    {:noreply, state}
  end

  def handle_cast({:barytherium, :disconnect, reason}, state = %{host: host, port: port}) do
    Logger.error("Connection to #{host}:#{port} disconnected for reason #{reason}")
    {:stop, :disconnected, state}
  end

  def handle_cast({:barytherium, :frames, {frames, sender_pid}}, state) do
    Enum.each(frames, &Util.single_frame/1)

    acknowledge_frame(sender_pid, List.last(frames))

    {:noreply, state}
  end

  def acknowledge_frame(sender_pid, %Frame{headers: headers}) do
    ack_id = Frame.headers_to_map(headers) |> Map.fetch!("ack")

    Sender.write(
      sender_pid,
      [%Frame{command: :ack, headers: [{"id", ack_id}]}]
    )
  end
end
