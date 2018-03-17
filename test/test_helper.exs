ExUnit.start()
require Logger
import Trappist 

Logger.debug "Deleting users"
:mnesia.delete_table :users

db(:users) |> save!(id: 1, name: "Boppy", email: "test@test.com")

count = :mnesia.table_info :users, :size
first = :mnesia.dirty_first(:users) |> IO.inspect 

Logger.debug "First user's id is #{first}"
Logger.debug "Locked and loaded with #{count} records"