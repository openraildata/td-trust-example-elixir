defmodule NetworkRailExample.TD do
  @moduledoc """
  Helpers for TD-representative structs
  """

  alias NetworkRailExample.TD.{BerthMovement, Heartbeat, SignallingState}

  @type td_struct :: BerthMovement.t() | Heartbeat.t() | SignallingState.t()

  @spec from_parsed_body([map()]) :: [td_struct()]

  def from_parsed_body(body) do
    body |> Enum.map(&Map.values/1) |> List.flatten() |> Enum.map(&from_map/1)
  end

  @spec from_map(map()) :: td_struct()

  def from_map(obj = %{"msg_type" => msg_type}) when msg_type in ["CA", "CB", "CC"] do
    BerthMovement.from_map(obj)
  end

  def from_map(obj = %{"msg_type" => "CT"}) do
    Heartbeat.from_map(obj)
  end

  def from_map(obj = %{"msg_type" => msg_type}) when msg_type in ["SF", "SG", "SH"],
    do: SignallingState.from_map(obj)

  @spec parse_td_timestamp(binary()) :: DateTime.t()

  def parse_td_timestamp(time_raw) do
    {timestamp, ""} = Integer.parse(time_raw)
    DateTime.from_unix!(div(timestamp, 1000), :second)
  end
end
