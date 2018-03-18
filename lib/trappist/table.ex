defmodule Trappist.Table do
  require Logger
  defmacro __using__([name: name, attributes: atts, indexes: indexes]) when is_list(atts) and is_list(indexes) do
    quote do
      import Trappist.Table
      @name unquote(name)
      @atts unquote(atts)
      @indexes unquote(indexes)

      require Logger
      
      defstruct @atts
      Trappist.Table.create_if_necessary(@name, @atts)
      Trappist.Table.create_indexes(@name, @indexes)

      def attributes do
        @atts
      end

      def save(%unquote(__CALLER__.module){} = map) do
        tuples = tupleize(map)
        res = :mnesia.transaction fn -> 
          :mnesia.write(tuples)
        end

        case res do
          {:ok} -> map
          {:atomic, _} -> map
          {:aborted, {:badarg, _} = stuff} -> 
            Logger.error "Problem with something"
            {:error, "There's a problem creating the table"}
        end
      end


      def find(id) do
        res = :mnesia.transaction fn -> 
          :mnesia.read({@name, id})
        end
       
        case res do
          {:atomic, []} -> nil
          {:atomic, [result_tuple]} -> result_tuple |> to_struct
        end
      end

      def where(criteria) do
        arg_list = for i <- 1..length(@atts), do: :"$#{i}"
        tupled_arg_list = arg_list |>  List.insert_at(0, @name) |> List.to_tuple
        criteria_keys = Keyword.keys criteria

        criteria_list = for {att, i} <- Enum.with_index(@atts) do 
          if att in criteria_keys do
            {:==, :"$#{i+1}", Keyword.get_values(criteria,att) |> List.first}
          end
        end |> Enum.reject(&is_nil/1)

        res = :mnesia.transaction fn -> 
          :mnesia.select(@name, [
            {
              tupled_arg_list, 
              criteria_list, 
              [:"$$"]
            }
          ])
        end

        case res do
          {:atomic, []} -> []
          {:atomic, lists} -> for l <- lists, do: l |> List.to_tuple |> to_struct
        end
        #:mnesia.dirty_select(:users, [{{:users, :"$1", :"$2", :"$3"}, [{:<, :"$1", 4}], [:"$$"]}]) 
        #:mnesia.dirty_index_read(:users, "rob@conery.io", :email)
      end

      def search_index(idx, term) do
        res =:mnesia.transaction fn ->
          :mnesia.index_read @name, term, idx
        end
        case res do
          {:atomic, []} -> []
          {:atomic, tuples} -> for t <- tuples, do: to_struct(t)
          {:aborted, _} -> "There was an error running this query. Check the name of your index."
        end
      end

      def to_kv(%unquote(__CALLER__.module){} = map) do
        res = []
        #match these up with the atts
        for att <- @atts do
          Keyword.put_new(res, att, Map.get(map, att))
        end |> List.flatten
      end

      def select_list do
        for i <- 1..length(@atts), do: "$#{i}"
      end

      def tupleize(%unquote(__CALLER__.module){} = map) do
        vals = to_kv(map)
        |> Keyword.values
        |> List.to_tuple 
        |> Tuple.insert_at(0, @name)
      end

      def to_struct(tuple) do
        stripped = tuple |> Tuple.to_list |>  List.delete_at(0)
        map = for {att, i} <- Enum.with_index(@atts) do
          {att, Enum.at(stripped, i)}
        end |> Enum.into(%{})
        struct(%unquote(__CALLER__.module){}, map)
      end
    end
  end

  def create_if_necessary(name, atts) do
    # this will simply return "Already exists" if its there
    # so no harm
    Logger.debug "Creating table"
    res = :mnesia.create_table name, disc_copies: [node()], attributes: atts, type: :ordered_set
    case res do
      {:atomic, :ok} -> Logger.info "Table created"
      _ -> Logger.info "Table exists, skipping"
    end
  end

  def create_indexes(name, indexes) do
    Logger.debug "Setting indexes"

    for idx <- indexes do
      :mnesia.add_table_index(name, idx)
    end
  end

end