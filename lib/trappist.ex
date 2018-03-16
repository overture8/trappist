defmodule Trappist do
  require Logger
  # make this an agent
  import Trappist.WriteCommand

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

  def save(table, map) when is_atom(table) and is_map(map) do
   
    %Trappist.WriteCommand{table: table, data_map: map}
    |> set_id
    |> tupleize
    |> try_save

  end

end
