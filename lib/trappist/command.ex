defmodule Trappist.Command do
  require Logger
  
  defstruct [
    table: nil,
    raw_result: nil,
    formatted_result: nil,
    table_created: false,
    attributes: [],
    list: nil,
    tupleized: nil,
    table_created: false
  ]

  def set_id(%Trappist.Command{} = cmd) do
    list = cond do
      Keyword.has_key?(cmd.list, :id) -> cmd.list
      true -> List.insert_at(cmd.list, 0, {:id, UUID.uuid1()})
    end 
    %{cmd | list: list}
  end

  def create_table(%Trappist.Command{table_created: false} = cmd) do
    #get the keys
    keys = Keyword.keys(cmd.list)
    :mnesia.create_table(cmd.table, attributes: keys, type: :ordered_set)
    %{cmd | table_created: true}
  end

  def tupleize(%Trappist.Command{} = cmd) do

    vals = Keyword.values(cmd.list) 
    |> List.to_tuple 
    |> Tuple.insert_at(0, cmd.table)
    
    %{cmd | tupleized: vals}
  end

  def try_save(%Trappist.Command{} = cmd) do
    cmd = %{cmd | attributes: Keyword.keys(cmd.list)}
    res = :mnesia.transaction fn -> 
      #Logger.debug "Writing..."
      :mnesia.write(cmd.tupleized)
    end

    case res do
      {:aborted, {:no_exists, _}} -> 
        #Logger.debug "Table doesn't exist, creating"
        cmd 
        |> create_table
        |> try_save
      {:aborted, _} -> {:error, "Error during write"}
      {:atomic, result} -> 
        #Logger.debug "Saved!"
        {:ok, Enum.into(cmd.list, %{})}
    end
  end
end