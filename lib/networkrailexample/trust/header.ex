defmodule NetworkRailExample.TRUST.Header do
  @moduledoc """
  * message_queue_timestamp (msg_queue_timestamp)  R Message queue timestamp (seconds since UNIX epoch as millisecond unit, converted to DateTime)
  * message_type            (msg_type)             R Padded numeric identifier (e.g. "0001" for an activation)
  * source_system_id                               R The direct origin of the message (e.g. "TRUST")
  * original_data_source                           O The originator of the data (e.g. "SMART")
  * source_device_id        (source_dev_id)        O CICS/LATA session
  * user_id                 (user_id)              O NCI signon

  (message types)
  https://wiki.openraildata.com/index.php?title=Train_Movements

  (includes descriptions for all header keys except message queue timestamp)
  https://wiki.openraildata.com/index.php?title=Train_Movement

  (device/user)
  https://wiki.openraildata.com/index.php?title=CICS_Session
  https://wiki.openraildata.com/index.php?title=LATA
  https://wiki.openraildata.com/index.php?title=NCI_signon
  """

  alias NetworkRailExample.TRUST

  @enforce_keys [
    :message_queue_timestamp,
    :message_type,
    :original_data_source,
    :source_device_id,
    :source_system_id,
    :user_id
  ]
  defstruct @enforce_keys

  def from_map(%{
        "msg_type" => message_type,
        "msg_queue_timestamp" => message_queue_timestamp_raw,
        "source_system_id" => source_system_id,
        "source_dev_id" => source_device_id,
        "original_data_source" => original_data_source,
        "user_id" => user_id
      }) do
    message_queue_timestamp_raw = TRUST.parse_trust_timestamp(message_queue_timestamp_raw)

    %__MODULE__{
      message_type: message_type,
      message_queue_timestamp: message_queue_timestamp_raw,
      original_data_source: original_data_source,
      source_system_id: source_system_id,
      source_device_id: source_device_id,
      user_id: user_id
    }
  end
end
