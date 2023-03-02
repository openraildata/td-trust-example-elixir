defmodule NetworkRailExample.TD.Heartbeat do
  @moduledoc """
  Representation of CT messages in TD, which are sent periodically by train describers as a sort of
  heartbeat.

  * time                    R          - Message time, expressed in millis since UNIX epoch (converted to DateTime)
  * area_id                 R          - Signalling area/Train Describer ID
  * message_type (msg_type) R          - CT
  * report_time             R          - Time of report (expressed as a string, e.g. "1041")
  """

  alias NetworkRailExample.TD

  @type t :: %__MODULE__{
          time: DateTime.t(),
          area_id: binary(),
          message_type: binary(),
          report_time: binary()
        }

  @enforce_keys [:time, :area_id, :message_type, :report_time]
  defstruct @enforce_keys

  def from_map(obj = %{"time" => time_raw, "area_id" => area_id, "msg_type" => "CT"}) do
    time = TD.parse_td_timestamp(time_raw)

    %__MODULE__{
      time: time,
      area_id: area_id,
      message_type: "CT",
      report_time: Map.fetch!(obj, "report_time")
    }
  end
end
