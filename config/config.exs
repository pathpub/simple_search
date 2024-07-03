import Config

# warning: setting dir seems to strangely force schema_location to RAM
config :mnesia,
  schema_location: :disc

# dir: "./tmp/#{config_env()}/Mnesia.#{node()}/"

import_config "#{config_env()}.exs"
