use Mix.Config

config :logger,
  level: :info

config :nostrum,
  token: "",
  num_shards: :auto

local_env_config = "#{Mix.env}.exs"
if File.regular?(local_env_config) do
  IO.puts "Loading local #{Mix.dev} configuration from #{local_env_config}"
  import_config local_env_config
end

external_config = "/var/bot/hourai/config/#{Mix.env}.exs"
if File.regular?(external_config) do
  IO.puts "Loading external configuration from #{external_config}..."
  import_config external_config
else
  IO.puts "No external configuration found at #{external_config}. Skipping external load..."
end

