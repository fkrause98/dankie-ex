defmodule Dankie.Ruleta.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def new_game(chat_id) do
    child_spec = {Dankie.Ruleta.Instance, chat_id}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def advance_game(chat_id) do
    case :global.whereis_name(chat_id) do
      :undefined ->
        {:error, :game_not_found}

      pid ->
        GenServer.call(pid, :pull_trigger)
    end
  end
end

defmodule Dankie.Ruleta.Instance do
  use GenServer

  def start_link(chat_id) do
    GenServer.start_link(__MODULE__, chat_id, name: {:global, chat_id})
  end

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
  def handle_call(:pull_trigger, _from, %{state: [:shoot | rest]} = game_state) do
    {:stop, :finished, :shoot, %{}}
  end
end
