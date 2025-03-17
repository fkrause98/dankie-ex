defmodule Dankie.Pole do
  use GenServer
  @timezone "America/Argentina/Buenos_Aires"

  alias Dankie.Pole.Storage

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def should_congratulate?(chat_id) do
    {:ok, now} = DateTime.now(@timezone)
    today = DateTime.to_date(now)

    case Storage.get_date(chat_id) do
      ^today ->
        :already_done

      _ ->
        Storage.store_date(chat_id, today)
        :ok
    end
  end

  def record_winner(chat_id, user_id) do
    GenServer.cast(__MODULE__, {:record_win, chat_id, user_id})
  end

  def get_leaderboard(chat_id) do
    Storage.get_leaderboard(chat_id)
  end

  def reset_state do
    Storage.reset_all()
  end

  def init(_) do
    Storage.start_link()
    {:ok, %{}}
  end

  def handle_cast({:record_win, chat_id, user_id}, state) do
    Storage.update_leaderboard(chat_id, user_id)
    {:noreply, state}
  end
end
