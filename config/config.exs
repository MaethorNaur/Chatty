import Config
for config <- "../apps/*/config/config.exs" |> Path.expand() |> Path.wildcard() do
  import_config config
end

config :logger, :console, metadata: [:pid]
