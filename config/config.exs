import Config

config :logger, :console,
  level: :info

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# mode can be :trust or :td
config :networkrailexample,
  mode: :td

import_config "secrets.exs"
