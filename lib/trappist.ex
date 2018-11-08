defmodule Trappist do
  require Logger
  # make this an agent
  import Trappist.Command

  def start() do
    # overture8: Commented this so I can control the
    # initialization of mnesia from my calling app. There
    # seems to be an issue with storage: :memory apps
    # where the mnesia initialization code (below) is not
    # called in time before the Trappist.Table macro kicks
    # in and tries to create the tables.

    # Logger.info("Starting Trappist")
    # opts = Application.get_env(:trappist, :storage)

    # dir = opts[:dir] || "/opt/mnesia"
    # node = opts[:node] || [node()]

    # Logger.info("Setting data directory to #{dir}")
    # :application.set_env(:mnesia, :dir, String.to_charlist(dir))

    # # no need to worry about overwrite
    # :mnesia.create_schema(node)

    # # #no need to worry about overwrite
    # :mnesia.start()

    # Logger.info("Ready...")
  end
end
