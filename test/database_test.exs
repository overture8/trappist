# defmodule Trappist.DatabaseTest do
#   use ExUnit.Case
  
#   defmodule TestDB do
#     use Trappist.Database
#     table :users do
#       attributes [:id, :name, :email]
#       index :email
#     end
#   end

#   describe "Basic agent stuff" do
#     setup do
#       {:ok, _} = Trappist.Table.start_link(:users, %{attributes: [:id, :email], indexes: []})
#       :ok
#     end
#     test "table attributes should be findable by name" do
#       atts = Trappist.Table.get_attributes(:users)
#       IO.inspect atts
#     end
#   end
  


# end