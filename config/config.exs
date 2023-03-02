import Config

config :logger, :console, level: :info

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# mode can be :trust, :td, or [:trust, :td]
config :networkrailexample,
  mode: :trust

import_config "secrets.exs"
