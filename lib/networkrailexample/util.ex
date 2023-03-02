defmodule NetworkRailExample.Util do
  import String, only: [pad_leading: 2]
  require Logger

  alias Barytherium.Frame

  # Berth step      - description moves from "from" berth into "to", "from" berth is erased
  @c_berth_step "CA"
  # Berth cancel    - description is erased from "from" berth
  @c_berth_cancel "CB"
  # Berth interpose - description is inserted into the "to" berth, previous contents erased
  @c_berth_interpose "CC"
  # Heartbeat       - sent periodically by a train describer
  @c_heartbeat "CT"

  # Signalling update
  @s_signalling_update "SF"
  # Signalling refresh
  @s_signalling_refresh "SG"
  # Signalling refresh finished
  @s_signalling_refresh_finished "SH"

  def print_td(td_msg) do
    {timestamp, ""} = Integer.parse(Map.get(td_msg, "time"))

    datetime_local =
      elem(DateTime.from_unix(timestamp, :millisecond), 1)
      |> DateTime.shift_zone!("Europe/London")
      |> DateTime.to_iso8601()

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
    signalling_id = String.slice(train_id, 2, 4)
    class = String.slice(train_id, 6, 1)

    "#{train_id} (#{signalling_id} #{class}) #{pad_leading(message_type, 14)} #{toc} #{loc_stanox} #{platform}"
  end

  def single_frame(%Frame{command: :message, body: body, headers: headers}) do
    header_map = Frame.headers_to_map(headers)

    destination = header_map["destination"]
    body_decoded = Jason.decode!(body)

    text =
      cond do
        String.starts_with?(destination, "/topic/TRAIN_MVT_") ->
          body_decoded
          |> Enum.map_join("\n", &print_trust/1)

        String.starts_with?(destination, "/topic/TD_") ->
          body_decoded
          |> Enum.map(fn x -> Map.values(x) end)
          |> List.flatten()
          |> Enum.filter(fn x ->
            Map.get(x, "msg_type") in [@c_berth_step, @c_berth_cancel, @c_berth_interpose]
          end)
          |> Enum.map_join("\n", &print_td/1)
      end

    IO.puts(text)
  end
end
