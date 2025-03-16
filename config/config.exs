import Config
config :tesla, :adapter, {Tesla.Adapter.Finch, name: MyFinch}


import_config "#{Mix.env()}.exs"
