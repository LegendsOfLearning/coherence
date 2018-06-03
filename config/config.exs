# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :coherence, Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: ""

import_config "#{Mix.env}.exs"

# Allow for additional overrides.
# Eg. `test.more.exs`
# Note `*.secret.exs` has been added to .gitignore
# so `test.secret.exs` will not be checked in
import_config "#{Mix.env}*.exs"
