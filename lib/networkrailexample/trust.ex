defmodule NetworkRailExample.TRUST do
  @moduledoc """
  Utilities for TRUST messages
  """

  alias NetworkRailExample.TRUST.{Header, Schema}

  @spec from_map(%{binary() => map()}) :: {map(), map()}

  def from_map(trust_map) do
    %{"body" => body_raw, "header" => header_raw} = Schema.inflate_parsed_trust(trust_map)

    header = Header.from_map(header_raw)

    {header, body_raw}
  end

  @spec parse_trust_timestamp(binary()) :: DateTime.t()

  def parse_trust_timestamp(time_raw) do
    {timestamp, ""} = Integer.parse(time_raw)
    DateTime.from_unix!(div(timestamp, 1000), :second)
  end
end
