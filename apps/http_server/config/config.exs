import Config
config :logger, :console,
  metadata: [:user, :pid]
