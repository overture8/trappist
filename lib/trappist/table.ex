defmodule Trappist.Table do
  defmacro __using__(opts) do
    unless opts[:attributes] do
      throw("Must have a list of attributes, such as [id: :auto, name: nil]")
    end

    atts = opts[:attributes]
    name = opts[:name] || __CALLER__.module
    Keyword.put(opts, :data, :rand.uniform())

    quote do
      import Trappist.Table

      @opts unquote(opts)
      @att_list unquote(atts)
      @name unquote(name)
      @atts unquote(Keyword.keys(atts))
      @defaults unquote(Keyword.values(atts))

      defstruct @att_list

      def name do
        @name
      end

      def attributes do
        @atts
      end

      def count do
        :mnesia.table_info(@name, :size)
      end

      def first do
        {:atomic, id} =
          :mnesia.transaction(fn ->
            :mnesia.first(@name)
          end)

        find(id)
      end

      def last do
        {:atomic, id} =
          :mnesia.transaction(fn ->
            :mnesia.last(@name)
          end)

        find(id)
      end

      def all do
        find(id: :"$$")
      end

      def save(list) when is_list(list) do
        list =
          for item <- list do
            tuples = decide_id(item) |> tupleize
          end

        res =
          :mnesia.transaction(fn ->
            for item <- list, do: :mnesia.write(item)
          end)

        case res do
          {:aborted, {:bad_type, _}} ->
            Trappist.Table.alter_table(@name, @atts)
            save(list)

          {:atomic, _} ->
            list

          _ ->
            {:error, "There was an error"}
        end
      end

      def save(%unquote(__CALLER__.module){} = map) do
        tuples = map |> decide_id |> tupleize

        res =
          :mnesia.transaction(fn ->
            :mnesia.write(tuples)
          end)

        case res do
          {:ok} ->
            map

          {:atomic, _} ->
            map

          {:aborted, {:bad_type, item}} ->
            Trappist.Table.alter_table(@name, @atts)
            save(map)

          {:aborted, {:badarg, _} = stuff} ->
            {:error, "There's a problem creating the table"}
        end
      end

      def decide_id(%unquote(__CALLER__.module){id: :auto} = map) do
        new_id = :mnesia.dirty_last(@name)

        incremented =
          cond do
            new_id == :"$end_of_table" -> 1
            true -> new_id = new_id + 1
          end

        %{map | id: incremented}
      end

      def decide_id(%unquote(__CALLER__.module){id: :uuid} = map) do
        # using this for sequentialness
        new_id = UUID.uuid1()
        %{map | id: new_id}
      end

      def decide_id(%unquote(__CALLER__.module){id: _} = map) do
        map
      end

      def find(id) do
        res =
          :mnesia.transaction(fn ->
            :mnesia.read({@name, id})
          end)

        case res do
          {:atomic, []} -> nil
          {:atomic, [result_tuple]} -> result_tuple |> to_struct
        end
      end

      def delete(id) do
        res =
          :mnesia.transaction(fn ->
            :mnesia.delete({@name, id})
          end)

        case res do
          {:atomic, :ok} -> :ok
          _ -> {:error, "There was an error deleting"}
        end
      end

      def pattern(args) do
        arg_keys = Keyword.keys(args)

        arg_list =
          for i <- 0..(length(@atts) - 1) do
            this_key = Enum.at(@atts, i)

            cond do
              this_key in arg_keys -> args[this_key]
              true -> :_
            end
          end

        tupled_arg_list = arg_list |> List.insert_at(0, @name) |> List.to_tuple()
      end

      def match do
        pattern([]) |> match
      end

      def match(pattern) do
        res =
          :mnesia.transaction(fn ->
            :mnesia.match_object(pattern)
          end)

        case res do
          {:atomic, []} -> []
          {:atomic, tuples} -> for t <- tuples, do: to_struct(t)
        end
      end

      def where(criteria) do
        arg_list = for i <- 1..length(@atts), do: :"$#{i}"
        tupled_arg_list = arg_list |> List.insert_at(0, @name) |> List.to_tuple()
        criteria_keys = Keyword.keys(criteria)

        criteria_list =
          for {att, i} <- Enum.with_index(@atts) do
            if att in criteria_keys do
              {:==, :"$#{i + 1}", Keyword.get_values(criteria, att) |> List.first()}
            end
          end
          |> Enum.reject(&is_nil/1)

        res =
          :mnesia.transaction(fn ->
            :mnesia.select(@name, [
              {
                tupled_arg_list,
                criteria_list,
                [:"$$"]
              }
            ])
          end)

        case res do
          {:atomic, []} -> []
          {:atomic, lists} -> for l <- lists, do: l |> List.to_tuple() |> to_struct
        end

        # :mnesia.dirty_select(:users, [{{:users, :"$1", :"$2", :"$3"}, [{:<, :"$1", 4}], [:"$$"]}]) 
      end

      def search_index(idx, term) do
        res =
          :mnesia.transaction(fn ->
            :mnesia.index_read(@name, term, idx)
          end)

        case res do
          {:atomic, []} -> []
          {:atomic, tuples} -> for t <- tuples, do: to_struct(t)
          {:aborted, _} -> "There was an error running this query. Check the name of your index."
        end
      end

      def to_kv(%unquote(__CALLER__.module){} = map) do
        res = []
        # match these up with the atts
        for att <- @atts do
          Keyword.put_new(res, att, Map.get(map, att))
        end
        |> List.flatten()
      end

      def select_list do
        for i <- 1..length(@atts), do: "$#{i}"
      end

      def tupleize(%unquote(__CALLER__.module){} = map) do
        vals =
          to_kv(map)
          |> Keyword.values()
          |> List.to_tuple()
          |> Tuple.insert_at(0, @name)
      end

      def to_struct(tuple) do
        stripped = tuple |> Tuple.to_list() |> List.delete_at(0)

        map =
          for {att, i} <- Enum.with_index(@atts) do
            {att, Enum.at(stripped, i)}
          end
          |> Enum.into(%{})

        struct(%unquote(__CALLER__.module){}, map)
      end
    end
  end

  def create_if_necessary(opts) do
    # this will simply return "Already exists" if its there
    # so no harm
    name = opts[:name]
    atts = opts[:attributes] |> Keyword.keys()

    type =
      case opts[:type] do
        nil -> :ordered_set
        :bag -> :bag
        :set -> :set
        :ordered_set -> :ordered_set
        _ -> throw("Don't know what type #{opts[:type]} is")
      end

    cond do
      opts[:storage] == :memory ->
        :mnesia.create_table(name, attributes: atts, type: type)

      true ->
        :mnesia.create_table(name, disc_copies: [node()], attributes: atts, type: type)
    end
  end

  def create_indexes(opts) do
    indexes = opts[:index] || []
    name = opts[:name]

    for idx <- indexes do
      :mnesia.add_table_index(name, idx)
    end
  end

  def alter_table(name, atts) do
    tupleized = atts |> List.insert_at(0, name) |> List.to_tuple()
    res = :mnesia.transform_table(name, fn existing -> existing end, atts)
  end
end
