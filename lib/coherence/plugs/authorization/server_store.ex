# defprotocol Coherence.ServerStore do
defmodule Coherence.ServerStore do
  @moduledoc """
  Database persistence of current_user data.

  Implement this protocol to add database storage, allowing session
  data to survive application restarts.
  """
  # @fallback_to_any true

  @type schema :: Ecto.Schema.t | Map.t
  @type gen_state :: term()
  @type cast_return :: {:noreply, new_state :: gen_state}
    | {:noreply, new_state :: gen_state, timeout() | :hibernate}
    | {:stop, reason :: term(), new_state :: gen_state}
  @type call_return :: {:reply, reply :: term(), new_state :: gen_state}
    | {:reply, reply :: term(), new_state :: gen_state, timeout() | :hibernate}
    | {:noreply, new_state :: gen_state}
    | {:noreply, new_state :: gen_state, timeout() | :hibernate}
    | {:stop, reason :: term(), reply :: term(), new_state :: gen_state}
    | {:stop, reason :: term(), new_state :: gen_state}

  @doc """
  Called on GenServer Init
  """
  @callback init(args :: term()) ::
    {:ok, state :: gen_state}
    | {:ok, state :: gen_state, timeout() | :hibernate}
    | :ignore
    | {:stop, reason :: any()}

  @doc """
  Called on GenServer stop
  """
  @callback stop(state :: gen_state) :: cast_return

  @doc """
  Get authenticated user data.
  """
  @callback get_user_data(HashDict.t, GenServer.from(), gen_state) :: call_return

  @doc """
  Save authenticated user data in the database.
  """
  @callback put_credentials(schema, HashDict.t, gen_state) :: cast_return

  @doc """
  Delete current user credentials.
  """
  @callback delete_credentials(HashDict.t, gen_state) :: cast_return

  @doc """
  """
  @callback update_user_logins(schema, gen_state) :: cast_return
end

