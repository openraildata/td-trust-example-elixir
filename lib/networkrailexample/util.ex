defmodule NetworkRailExample.Util do
  @moduledoc false

  import String, only: [pad_leading: 2, pad_leading: 3]
  require Logger

  alias NetworkRailExample.TRUST.Header
  alias NetworkRailExample.TD.{BerthMovement, Heartbeat, SignallingState}

  def format_parsed(
        {%Header{message_type: message_type, message_queue_timestamp: message_queue_timestamp},
         body = %{"train_id" => train_id}}
      ) do
    datetime = DateTime.to_iso8601(message_queue_timestamp)
    toc = Map.get(body, "toc_id", "  ")
    loc_stanox = "@" <> Map.get(body, "loc_stanox", "")
    platform = Map.get(body, "platform", "")

    origin_stanox_trunc = String.slice(train_id, 0, 2)
    signalling_id = String.slice(train_id, 2, 4)
    class = String.slice(train_id, 6, 1)
    call_code = String.slice(train_id, 7, 1)
    train_id_dom = String.slice(train_id, 8, 2)

    "#{datetime} [#{message_type}] (#{train_id}: #{origin_stanox_trunc} #{signalling_id} #{class} #{call_code} #{train_id_dom}) #{toc} #{loc_stanox} #{platform}"
  end

  def format_parsed(
        {%Header{message_type: message_type, message_queue_timestamp: message_queue_timestamp},
         _body}
      ) do
    datetime = DateTime.to_iso8601(message_queue_timestamp)

    "#{datetime} [#{message_type}]"
  end

  def format_parsed(%BerthMovement{
        time: time,
        area_id: area_id,
        message_type: message_type,
        description: description,
        from: from,
        to: to
      }) do
    datetime = DateTime.to_iso8601(time)
    from_berth = from || ""
    to_berth = to || ""

    "#{datetime}   [#{message_type}] #{area_id} #{pad_leading(description, 4)} #{pad_leading(from_berth, 5)} -> #{pad_leading(to_berth, 5)}"
  end

  def format_parsed(%Heartbeat{
        time: time,
        area_id: area_id,
        message_type: message_type,
        report_time: report_time
      }) do
    datetime = DateTime.to_iso8601(time)
    "#{datetime}   [#{message_type}] #{area_id} #{pad_leading(report_time, 4)}"
  end

  def format_parsed(%SignallingState{
        time: time,
        area_id: area_id,
        message_type: message_type,
        address: address,
        data: data
      }) do
    datetime = DateTime.to_iso8601(time)

    "#{datetime}   [#{message_type}] #{area_id} #{pad_leading("", 19)} | #{address |> Integer.to_string(16) |> pad_leading(2, "0")} #{:binary.encode_hex(data) |> pad_leading(8)}"
  end
end
