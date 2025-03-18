defmodule Dankie.Pole do
  @moduledoc """
  Handles the logic for tracking daily poles and managing leaderboards.
  """

  @timezone "America/Argentina/Buenos_Aires"
  alias Dankie.Pole.Storage

  @doc """
  Checks if the chat should be congratulated for the first message of the day.
  Returns :must_congratulate if congratulations are needed, :already_done otherwise.
  """
  def should_congratulate?(chat_id) do
    {:ok, now} = DateTime.now(@timezone)
    today = DateTime.to_date(now)

    case Storage.get_date(chat_id) do
      ^today ->
        :already_done

      _ ->
        Storage.store_date(chat_id, today)
        :must_congratulate
    end
  end

  @doc """
  Records a winner in the leaderboard for the specified chat.
  """
  def record_winner(chat_id, %{id: user_id, username: username}) do
    Storage.update_leaderboard(chat_id, user_id, username)
  end

  @doc """
  Retrieves the leaderboard for the specified chat.
  """
  def get_leaderboard(chat_id) do
    Storage.get_leaderboard(chat_id)
  end

  @doc """
  Resets the state (for testing or manual resets).
  """
  def reset_state do
    Storage.reset_all()
  end

  @doc """
  Formats the leaderboard into a readable string.
  """
  def format_leaderboard(leaderboard) when map_size(leaderboard) == 0 do
    "No hay poles todavía"
  end

  def format_leaderboard(leaderboard) do
    entries =
      leaderboard
      |> Enum.sort_by(fn {_user, count} -> -count end)
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {{{user_id, username}, count}, index} ->
        user = if username, do: "#{username}", else: "Usuario #{user_id}"
        "#{index}. #{user}: #{count} veces"
      end)

    "🏆 Clasificación de Poles 🏆\n\n#{entries}"
  end
end
