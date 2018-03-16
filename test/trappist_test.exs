defmodule TrappistTest do
  use ExUnit.Case
  describe "Your mom" do
    test "saves the data" do
      Trappist.save(:users, %{name: "chicken"})
    end
  end
end
