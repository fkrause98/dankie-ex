defmodule Dankie.Ruleta do
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link do
    Registry.start_link(keys: :unique, name: Dankie.Ruleta.Registry)
  end

  def new_game(chat_id) do
    case GenServer.start_link(__MODULE__, chat_id, name: via_tuple(chat_id)) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  def advance_game(chat_id) do
    case lookup_game(chat_id) do
      nil -> {:error, :game_not_found}
      pid -> GenServer.call(pid, :pull_trigger)
    end
  end

  defp via_tuple(chat_id) do
    {:via, Registry, {Dankie.Ruleta.Registry, chat_id}}
  end

  defp lookup_game(chat_id) do
    case Registry.lookup(Dankie.Ruleta.Registry, chat_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  # Server callbacks
  @impl true
  def init(chat_id) do
    five_empties = for n <- [1, 2, 3, 4, 5], do: :empty
    randomized = Enum.shuffle(five_empties ++ [:shoot])
    {:ok, %{chat_id: chat_id, state: randomized}}
  end

  @impl true
  def handle_call(:pull_trigger, _from, %{state: [:empty | rest]} = game_state) do
    {:reply, :empty, %{game_state | state: rest}}
  end

  @impl true
  def handle_call(:pull_trigger, _from, %{state: [:shoot | _rest]} = _game_state) do
    {:stop, :normal, :shoot, %{}}
  end
end
