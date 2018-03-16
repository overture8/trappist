defmodule Trappist.WriteCommand do
  alias Trappist.WriteCommand
  require Logger

  defstruct [
    table: nil,
    data_map: nil,
    tupleized: nil,
    table_created: false
  ]

  def set_id(%WriteCommand{} = cmd) do
    map = cond do
      Map.has_key?(cmd.data_map,:id) -> cmd.data_map 
      true -> Map.put(cmd.data_map, :id, UUID.uuid1()) 
    end 
    %{cmd | data_map: map}
  end

  def create_table(%WriteCommand{table_created: false} = cmd) do
    #get the keys
    keys = Map.keys(cmd.data_map) 
    :mnesia.create_table(cmd.table, attributes: keys, type: :ordered_set)
    %{cmd | table_created: true}
  end

  def tupleize(%WriteCommand{} = cmd) do
    vals = cmd.data_map 
    |> Map.values 
    |> List.to_tuple 
    |> Tuple.insert_at(0, cmd.table)
    
    %{cmd | tupleized: vals}
  end

  def try_save(%Trappist.WriteCommand{} = cmd) do
    res = :mnesia.transaction(fn -> 
      Logger.debug "Writing..."
      #:mnesia.write(table, Map.values(tupleized))
      :mnesia.write(cmd.tupleized)
    end)

    case res do
      {:aborted, {:no_exists, _}} -> 
        Logger.debug "Table doesn't exist, creating"
        cmd 
        |> create_table
        |> try_save
      {:aborted, _} -> {:error, "Error during write"}
      {:atomic, result} -> 
        Logger.debug "Saved!"
        {:ok, result}
    end
  end
end