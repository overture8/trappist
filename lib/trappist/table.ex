# defmodule Trappist.Table do
#   require Logger
#   defmacro __using__([name: name, attributes: atts, indexes: indexes]) do
#     quote do
#       import Trappist.Table
#       @name unquote(name)
#       @atts unquote(atts)
#       @indexes unquote(indexes)
#       require Logger
      
#       def attributes do
#         @atts
#       end

#       def save(data) do
#         %Trappist.Command{table: @name,data_map: data} 
#         |> set_id
#         |> set_struct
#         |> tupleize
#         |> try_save
#       end
      
#       def save!(data) when is_map(data) do
#         res = save(data)
#         case res do
#           {:ok, saved} -> saved
#           {:error, err} -> throw err
#         end
#       end

#       def select_list do
#         for i <- 1..length(@atts), do: "$#{i}"
#       end

#     end
#   end

#   def set_id(%Trappist.Command{} = cmd) do
#     map = cond do
#       Map.has_key?(cmd.data_map,:id) -> cmd.data_map 
#       true -> Map.put(cmd.data_map, :id, UUID.uuid1()) 
#     end 
#     %{cmd | data_map: map}
#   end

#   #TODO: Probably a better way to do this, but for now this saves a wonky
#   #restructuring of the record at the expense of disk space... which I think 
#   #is OK... maybe?
#   def set_struct(%Trappist.Command{}=cmd) do
#     map = Map.put(cmd.data_map, :zzz, cmd.data_map)
#     %{cmd | data_map: map}
#   end

#   def create_table(%Trappist.Command{table_created: false} = cmd) do
#     #get the keys
#     keys = Map.keys(cmd.data_map) 
#     :mnesia.create_table(cmd.table, attributes: keys, type: :ordered_set)
#     %{cmd | table_created: true}
#   end

#   def tupleize(%Trappist.Command{} = cmd) do
#     vals = cmd.data_map 
#     |> Map.values 
#     |> List.to_tuple 
#     |> Tuple.insert_at(0, cmd.table)
    
#     %{cmd | tupleized: vals}
#   end

#   def try_save(%Trappist.Command{} = cmd) do

#     res = :mnesia.transaction fn -> 
#       :mnesia.write(cmd.tupleized)
#     end

#     case res do
#       {:aborted, {:no_exists, _}} -> 
#         Logger.debug "Table doesn't exist, creating"
#         cmd 
#         |> create_table
#         |> try_save
#       {:aborted, err} -> 
#         Logger.error "BUMMER"
#         IO.inspect err
#         {:error, "Error during write"}
#       {:atomic, result} -> 
#         {:ok, cmd.data_map}
#     end
#   end

# end