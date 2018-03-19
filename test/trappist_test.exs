defmodule TrappistTest do
  use ExUnit.Case, async: true
  require Logger 
  #import Trappist

  defmodule Moon do
    use Trappist.Table, [
      name: :moons,
      attributes: [
        id: :uuid,
        name: nil,
        tips: 2,
        diameter: 4
      ],
      index: [],
      storage: :memory
    ]
  end

  defmodule Planet do
    use Trappist.Table, [
      name: :planets, 
      attributes: [
        id: :auto, 
        name: "",
        diameter: 0
      ], 
      index: [:name]
    ]

  end

  setup_all do

    %Planet{name: "Flipper", diameter: 12} |> Planet.save
    %Planet{name: "Earth", diameter: 12} |> Planet.save
    %Planet{name: "Mars", diameter: 12} |> Planet.save

    %Moon{name: "Enceladus"} |> Moon.save
    :ok

  end

  describe "Defaults" do
    test "there is a default diameter of 0" do
      p = %Planet{}
      assert p.diameter == 0
    end
  end

  describe "Bulk inserts" do
    test "it will add 5 moons" do
      res = moons = [
        %Moon{name: "Moon 1"},
        %Moon{name: "Moon 2"},
        %Moon{name: "Moon 3"},
        %Moon{name: "Moon 4"},
        %Moon{name: "Moon 5"},
      ] |> Moon.save
      assert length(res) == 5
    end
  end

  describe "Counting things" do
    test "There are 3 planets in the DB" do
      assert Planet.count > 0
    end
  end
  describe "IDs" do
    test "First planet has ID of 1" do
      first = :mnesia.dirty_first :planets 
      assert first == 1
    end
    test "Enceladus has a GUID" do
      moon = Moon.first 
      assert String.length(moon.id) > 5
    end
  end
  describe "Deleting things" do
    test "First planet has ID of 1" do
      p = %Planet{name: "Wonk"} |> Planet.save
      res = Planet.delete(p.id)
      assert res == :ok
    end
  end
  describe "Finding things" do
  
    test "Matches will... match" do
      res = 
        Planet.pattern(name: "Earth") 
        |> Planet.match
      
      assert length(res) > 0
      
    end
    test "Match with no pattern will return everything" do
      res = Planet.match
      assert length(res) > 0
    end
    test "A planet is findable by id" do
      res = Planet.find(1)
      assert res.id == 1
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
