defmodule Trappist.Database do
  
  defmacro __using__(_opts) do
    quote do
      import Trappist.Database
      import Trappist.Table

    end
  end

  def attributes(list) do
    #IO.inspect list
  end

  def index(attribute) do
    #IO.inspect attribute
  end
  


  defmacro table(name, do: block) do
    quote do
      import Trappist.Database
      unquote(block)
    end
  end



end