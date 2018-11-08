# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

IO.inspect("HERE")

opts = Application.get_env(:trappist, :storage)
dir = opts[:dir] || "/opt/mnesia"
node = opts[:node] || [node()]
:application.set_env(:mnesia, :dir, String.to_charlist(dir))
:mnesia.create_schema(node)
:mnesia.start()

import_config "#{Mix.env()}.exs"
