ExUnit.start()
require Logger
#import Trappist 

:mnesia.delete_table :planets
:mnesia.delete_table :moons
