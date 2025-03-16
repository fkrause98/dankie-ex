import Config
config :tesla, :adapter, {Tesla.Adapter.Finch, name: MyFinch}

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

import_config "#{Mix.env()}.exs"
