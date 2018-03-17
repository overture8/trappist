defmodule TrappistTest do
  use ExUnit.Case
  require Logger 
  import Trappist
  # defmodule TestTable do
  #   use Trappist.Table, [
  #     name: :users, 
  #     attributes: [:id, :name, :email], 
  #     indexes: :email
  #   ]
  # end

  describe "Finding by ID" do
    test "Can find a user by ID" do
      found = db(:users) |> find(1)
      #assert found.id == 1
      IO.inspect found
    end
  end
  
  # describe "Finding by match" do
  #   test "Can find a user by ID" do
  #     found = db(:users) |> match({:_, "Skippy"})
  #     assert found.id == 2
  #   end
  # end

  # describe "Finding by filter" do
  #   test "Can find a user by criteria" do
  #     x = db(:users) |> filter(name: "Steve")
  #     IO.inspect x
  #   end
  # end
end
