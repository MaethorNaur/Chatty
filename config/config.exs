import Config
config :logger, :console,
  metadata: [:user, :crash_reason, :pid]
