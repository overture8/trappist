ExUnit.start()
require Logger

:mnesia.delete_table(:users)
Logger.info "Table deleted"