# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :phoenix, :json_library, Jason

config :coherence, Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: ""

import_config "#{config_env()}.exs"

# Allow for additional overrides.
# Eg. `test.more.exs`
# Note `*.secret.exs` has been added to .gitignore
# so `test.secret.exs` will not be checked in
for config <- "#{config_env()}.*.exs" |> Path.expand(__DIR__) |> Path.wildcard() do
  import_config config
end
