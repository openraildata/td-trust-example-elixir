defmodule NetworkRailExample.TD.BerthMovement do
  @moduledoc """

  Representation of CA, CB, and CC messages in TD, which represent the movement of
  descriptions between describer berths

  There are three "C-class" message types which relate to berth movements:
  * CA - Berth step   - a description moves from "from" berth into "to". "from" berth is erased.
  * CB - Berth cancel - description is erased from "from" berth
  * CC - Berth interpose - description is inserted into "to" berth, previous contents erased.

  There's charts available which should help with this, see the wiki link below.

  Struct key (Feed key), O denotes 'optional', R is 'required'

  * time                    R          - Message time, expressed in millis since UNIX epoch (converted to DateTime)
  * area_id                 R          - Signalling area/Train Describer ID
  * message_type (msg_type) R          - CA, CB, or CC
  * description  (descr)    R          - Description being stepped/cancelled/interposed
  * from                    R (CA, CB) - The berth the description is moved (or erased) from
  * to                      R (CA, CC) - The berth the description is moved (or inserted) into

  https://wiki.openraildata.com/index.php?title=C_Class_Messages
  """

  alias NetworkRailExample.TD

  @typedoc """
  A berth ID is a four-character alphanumeric ID (e.g. "4007") which uniquely identifies the given
  berth within a signalling area
  """
  @type berth :: binary()

  @typedoc """
  A description often represents the signalling identifier ("headcode") of a train, but can represent other things too,
  e.g. the current time (in a clock berth), the signaller can set custom contents to indicate possessions, blocks, failed units,
  and so on.
  """
  @type td_description :: binary()

  @type t :: %__MODULE__{
          time: DateTime.t(),
          area_id: binary(),
          message_type: binary(),
          description: td_description(),
          from: berth(),
          to: berth()
        }

  @enforce_keys [:time, :area_id, :message_type, :description, :from, :to]
  defstruct @enforce_keys

  def from_map(
        obj = %{
          "time" => time_raw,
          "area_id" => area_id,
          "msg_type" => message_type_raw,
          "descr" => description
        }
      ) do
    time = TD.parse_td_timestamp(time_raw)

    %__MODULE__{
      time: time,
      area_id: area_id,
      message_type: message_type_raw,
      description: description,
      from: Map.get(obj, "from"),
      to: Map.get(obj, "to")
    }
  end
end
