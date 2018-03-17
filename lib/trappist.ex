defmodule Trappist do
  require Logger
  # make this an agent
  import Trappist.Command

  def start() do
    Logger.info "Starting Trappist"    
    #need to make sure :mnesia is configured properly
    
    Logger.info "Setting data directory"
    :application.set_env(:mnesia, :dir, '/Users/rob/mnesia')
    
    #no need to worry about overwrite
    :mnesia.create_schema([node()])
    :mnesia.start()

    Logger.info "Ready..."
  end

  def db(table) when is_atom(table) do
    %Trappist.Command{table: table}
  end

  def find(%Trappist.Command{table: table} = cmd, id) do
    res = :mnesia.transaction fn -> 
      :mnesia.read({table, id})
    end
    case res do
      {:atomic, []} -> nil
      {:atomic, [result_tuple]} -> tuple_to_map(table, result_tuple)
        

    end
  end

  def tuple_to_map(table, tuple) do
    stripped = tuple |> Tuple.to_list |>  List.delete_at(0)
    atts = :mnesia.table_info table, :attributes
    for {att, i} <- Enum.with_index(atts) do
      {att, Enum.at(stripped, i)}
    end |> Enum.into(%{})
  end

  def match(%Trappist.Command{table: table} = cmd, criteria) when is_tuple(criteria) do
    tupleized = criteria 
    |> Tuple.insert_at(0, table)
    |> Tuple.append(:_) #account for the last record, which is the saved map
    
    res = :mnesia.transaction fn ->
      :mnesia.match_object(tupleized)
    end
    case res do
      {:atomic, []} -> []
      {:atomic, [result_tuple]} -> result_tuple 
                                  |> Tuple.to_list 
                                  |> List.last
    end
  end

  def filter(%Trappist.Command{table: table} = cmd, criteria) do
    attributes = :mnesia.table_info(:users, :attributes)
    arg_list = for i <- 1..length(attributes), do: :"$#{i}"
    tupled_arg_list = arg_list |>  List.insert_at(0, table) |> List.to_tuple
    criteria_keys = Keyword.keys criteria

    criteria_list = for {att, i} <- Enum.with_index(attributes) do 
      if att in criteria_keys do
        {:==, :"$#{i+1}", Keyword.get_values(criteria,att) |> List.first}
      end
    end |> Enum.reject(&is_nil/1)

    res = :mnesia.transaction fn -> 
      :mnesia.select(table, [
        {
          tupled_arg_list, 
          criteria_list, 
          [:"$$"]
        }
      ])
    end

    case res do
      {:atomic, []} -> []
      {:atomic, [result_tuple]} -> result_tuple 
    end
    #:mnesia.dirty_select(:users, [{{:users, :"$1", :"$2", :"$3"}, [{:<, :"$1", 4}], [:"$$"]}]) 
    #:mnesia.dirty_index_read(:users, "rob@conery.io", :email)
  end

  def save(%Trappist.Command{} = cmd, item) when is_list(item) do
    %{cmd | list: item}
    |> set_id
    |> tupleize
    |> try_save
  end

  def save!(%Trappist.Command{} = cmd, item) when is_list(item) do
    res = save(cmd, item)

    case res do
      {:ok, saved} -> saved
      {:error, err} -> throw err
    end
  end

end
