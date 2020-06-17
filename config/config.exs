import Config

config :logger, :console,
  level: :debug,
  format: "[$level] $time $metadata $message\n",
  metadata: [:user]

config :libcluster,
  topologies: [
    chatty: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:"a@127.0.0.1", :"b@127.0.0.1"]]
    ]
    # consul_example: [
    # strategy: ClusterConsul.Strategy,
    # config: [
    # service_name: "teamweek-core"
    # ]
    # ]
  ]
