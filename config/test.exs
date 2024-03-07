import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :payment_server, PaymentServer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "payment_server_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :payment_server,
  supported_currencies: [
    "CAD", "USD", "AUD"
  ],
  exchange_rate_endpoint: PaymentServer.Support.ExchangeRate.TestEndpoint,
  exchange_rate_update_frequency_ms: 20,
  exchange_rate_use_default_publish_fn: false


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :payment_server, PaymentServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "r2YxJHiuwqyebaOGyUu21jpgb6+nbvX07XFUGidKN/i5e1wUc5bnBIfjAqKdqy6p",
  server: false

# In test we don't send emails.
config :payment_server, PaymentServer.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
