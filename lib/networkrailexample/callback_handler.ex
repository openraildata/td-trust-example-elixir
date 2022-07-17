defmodule NetworkRailExample.CallbackHandler do
  use GenServer
  alias Mammoth.Message
  import String, only: [pad_leading: 2]
  alias NetworkRailExample.BackoffManager
  require Logger

  @c_berth_step      "CA"  # Berth step      - description moves from "from" berth into "to", "from" berth is erased
  @c_berth_cancel    "CB"  # Berth cancel    - description is erased from "from" berth
  @c_berth_interpose "CC"  # Berth interpose - description is inserted into the "to" berth, previous contents erased
  @c_heartbeat       "CT"  # Heartbeat       - sent periodically by a train describer

  @s_signalling_update "SF"            # Signalling update
  @s_signalling_refresh "SG"           # Signalling refresh
  @s_signalling_refresh_finished "SH"  # Signalling refresh finished

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{client: nil, opts: opts})
  end

  def init(state) do
    interval = BackoffManager.get_interval(state.opts.id)
    Logger.info("#{state.opts.id} waiting before attempting (re)connection #{interval}ms")
    Process.send_after(self(), :connect, interval)
    state = Map.put(state, :connected, false)
    {:ok, state}
  end

  def print_td(td_msg) do
    {timestamp, ""} = Integer.parse(Map.get(td_msg, "time"))
    datetime_local = elem(DateTime.from_unix(timestamp, :millisecond),1) |> DateTime.from_naive!("UTC") |> DateTime.shift_zone!("Europe/London") |> DateTime.to_iso8601

    area_id = Map.get(td_msg, "area_id")
    message_type = Map.get(td_msg, "msg_type")
    description = Map.get(td_msg, "descr", "")
    from_berth = Map.get(td_msg, "from", "")
    to_berth = Map.get(td_msg, "to", "")

    "#{datetime_local} [#{message_type}] #{area_id} #{pad_leading(description, 4)} #{pad_leading(from_berth, 5)} -> #{pad_leading(to_berth, 5)}"
  end

  def print_trust(trust_msg) do
    body = Map.get(trust_msg, "body")
    toc = Map.get(body, "toc_id", "")
    platform = Map.get(body, "platform", "")
    loc_stanox = "@" <> Map.get(body, "loc_stanox", "")
    message_type = trust_msg |> Map.get("header") |> Map.get("msg_type")

    train_id = Map.get(body, "train_id")
    signalling_id = String.slice(train_id, 2,4)
    class = String.slice(train_id, 6, 1)

    "#{train_id} (#{signalling_id} #{class}) #{pad_leading(message_type, 14)} #{toc} #{loc_stanox} #{platform}"
  end

  def handle_info(:connect, state) do
    {:ok, client} = Mammoth.start_link(self())
    Mammoth.connect(client, state.opts.host, state.opts.port, "/", state.opts.user, state.opts.pass)

    Mammoth.subscribe(client, state.opts.queue, :client)

    {:noreply, Map.put(state, :client, client)}
  end

  def handle_info({:mammoth, :receive_frame, message = %Message{command: :error}}, state) do
    Logger.error("Mammoth error: #{inspect(message)}")
    {:stop, :connect_error, state}
  end

  def handle_info(
        {:mammoth, :receive_frame, message = %Message{command: :message, body: body}},
        state = %{client: client}
      ) do

    {:ok, destination} = Message.get_header(message, "destination")
    body_decoded = Jason.decode!(body)

    text = cond do
      String.starts_with?(destination, "/topic/TRAIN_MVT_") ->
        body_decoded |>
        Enum.map_join("\n", &print_trust/1)
      String.starts_with?(destination, "/topic/TD_") ->
        body_decoded |>
        Enum.map(fn x -> Map.values(x) end) |>
        List.flatten |>
        Enum.filter(fn x -> Map.get(x, "msg_type") in [@c_berth_step, @c_berth_cancel, @c_berth_interpose] end) |>
        Enum.map_join("\n", &print_td/1)
    end

    IO.puts text

    Mammoth.send_ack_frame(client, message)
    {:noreply, state}
  end

  def handle_info({:mammoth, :receive_frame, message = %Message{command: :connected}}, state) do
    Logger.info("Mammoth connection success: #{inspect(message)}")
    BackoffManager.notify_success(state.opts.id)
    {:noreply, state}
  end

  def handle_info({:mammoth, :receive_frame, message}, state) do
    Logger.debug("Some other sort of message: #{inspect(message)}")
    {:noreply, state}
  end

  def handle_info({:mammoth, :disconnected, :local}, state) do
    Logger.info("Mammoth confirmation received for disconnection")
    {:stop, :connect_disconnected, state}
  end

  def handle_info({:mammoth, :disconnected, :remote}, state) do
    Logger.error("Mammoth connection closed by remote host")
    BackoffManager.notify_failure(state.opts.id)
    {:stop, :connect_disconnected, state}
  end

  def handle_info({:mammoth, :disconnected, :parse_error}, state) do
    Logger.error("Mammoth connection closed by local end because of a parsing error")
    BackoffManager.notify_failure(state.opts.id)
    {:stop, :connect_disconnected, state}
  end

  def handle_info({:mammoth, :disconnected, :timeout}, state) do
    Logger.error("Mammoth connection closed by local end because of a timeout")
    BackoffManager.notify_failure(state.opts.id)
    {:stop, :connect_disconnected, state}
  end
end
