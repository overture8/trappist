ExUnit.start()
require Logger
#import Trappist 


count = :mnesia.table_info :planets, :size
count2 = :mnesia.table_info :moons, :size
Logger.debug "Starting tests with #{count} planets"
Logger.debug "Starting tests with #{count2} moons"


:mnesia.delete_table(:planets)
:mnesia.delete_table(:moons)




# db(:users) |> save!(id: 1, name: "Boppy", email: "test@test.com")
# db(:users) |> save!(id: 2, name: "Xiv", email: "test1@test.com")
# db(:users) |> save!(id: 3, name: "Sullivan", email: "test2@test.com")
# db(:users) |> save!(id: 4, name: "Lamb", email: "test3@test.com")
# db(:users) |> save!(id: 5, name: "Winn", email: "test4@test.com")

# count = :mnesia.table_info :users, :size
# first = :mnesia.dirty_first(:users) |> IO.inspect 

# Logger.debug "First user's id is #{first}"
# Logger.debug "Locked and loaded with #{count} records"