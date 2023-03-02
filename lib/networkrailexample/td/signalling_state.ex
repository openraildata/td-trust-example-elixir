defmodule NetworkRailExample.TD.SignallingState do
  @moduledoc """
  Signalling state updates for an area

  There's three "S-class" message types:
  * SF - Signalling update           - updates part of the signalling state for a train describer
  * SG - Signalling refresh          - part of a series of SG messages refreshing the entire signalling state
  * SH - Signalling refresh finished - final message in a describer refresh

  Struct key (Feed key), O denotes 'optional', R is 'required'

  * time                    R Message time, expressed in millis since UNIX epoch      (converted to DateTime)
  * area_id                 R Signalling area/Train Describer ID
  * message_type (msg_type) R Message type - SF, SG, or SH
  * address                 R Address, expressed in hexadecimal, of the inserted data (converted to integer)
  * data                    R Data, 1-4 bytes expressed in hexadecimal                (converted to binary)

  https://wiki.openraildata.com/index.php?title=S_Class_Messages
  https://wiki.openraildata.com/index.php?title=Decoding_S-Class_Data
  """

  alias NetworkRailExample.TD

  @type t :: %__MODULE__{
          time: DateTime.t(),
          area_id: binary(),
          message_type: binary(),
          address: integer(),
          data: binary()
        }

  @enforcekeys [:time, :area_id, :message_type, :address, :data]
  defstruct @enforcekeys

  def from_map(%{
        "time" => time_raw,
        "area_id" => area_id,
        "msg_type" => message_type_raw,
        "address" => address_raw,
        "data" => data_raw
      }) do
    time = TD.parse_td_timestamp(time_raw)

    {address, ""} = Integer.parse(address_raw, 16)

    %__MODULE__{
      time: time,
      area_id: area_id,
      message_type: message_type_raw,
      address: address,
      data: :binary.decode_hex(data_raw)
    }
  end
end
