defmodule TrappistTest do
  use ExUnit.Case, async: true
  require Logger 
  #import Trappist

  defmodule Planet do
    use Trappist.Table, [
      name: :planets, 
      attributes: [
        :id, 
        :name, 
        :diameter
      ], 
      indexes: [:name]
    ]
  end

  describe "Finding things" do
    
    setup do
      %Planet{id: 10, name: "Flipper", diameter: 12} |> Planet.save
      %Planet{id: 1, name: "Earth", diameter: 12} |> Planet.save
      %Planet{id: 2, name: "Mars", diameter: 12} |> Planet.save

      :ok
    end

    test "This is whack" do
      res = Planet.find(10)
      assert res.id == 10
    end
    test "Data is in the DB" do
      first = :mnesia.dirty_first :planets
      assert first > 0
    end
    test "its queryable by index" do
      res = Planet.search_index :name, "Earth"
      assert length(res) == 1
    end
    test "its queryable by where" do
      res = Planet.where(name: "Earth")
      assert length(res) == 1
    end
  end

  # describe "Finding by ID" do
  #   test "Can find a user by ID" do
  #     found = db(:users) |> find(1)
  #     assert found.id == 1
      
  #   end
  # end
  
  # describe "Finding by match" do
  #   test "Can find a user by ID" do
  #     found = db(:users) |> match({:_, "Skippy"})
  #     #assert found.id == 2
  #   end
  # end

  # describe "Finding by filter" do
  #   test "Can find a user by criteria" do
  #     x = db(:users) |> filter(email: "test@test.com")
  #     IO.inspect x
  #   end
  # end
end
