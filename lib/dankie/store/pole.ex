defmodule Dankie.Pole.Storage do
  @moduledoc """
  Persistent storage using RocksDB for daily tracking and leaderboards.
  """

  @rocksdb_path "./store/pole_data"
  @rocksdb_options [create_if_missing: true]

  @doc """
  Opens a RocksDB connection and yields it to the given function.
  """
  defp with_db(fun) do
    {:ok, db} = :rocksdb.open(String.to_charlist(@rocksdb_path), @rocksdb_options)

    try do
      fun.(db)
    after
      :rocksdb.close(db)
    end
  end

  @doc """
  Stores the current date for a chat.
  """
  def store_date(chat_id, date) do
    with_db(fn db ->
      key = "date:#{chat_id}"
      :rocksdb.put(db, key, :erlang.term_to_binary(date), [])
    end)
  end

  @doc """
  Retrieves the stored date for a chat.
  """
  def get_date(chat_id) do
    with_db(fn db ->
      key = "date:#{chat_id}"

      case :rocksdb.get(db, key, []) do
        {:ok, bin} -> :erlang.binary_to_term(bin)
        :not_found -> nil
      end
    end)
  end

  @doc """
  Updates the leaderboard for a chat with a new winner.
  """
  def update_leaderboard(chat_id, user_id, username) do
    with_db(fn db ->
      key = "leaderboard:#{chat_id}"

      current =
        case :rocksdb.get(db, key, []) do
          {:ok, bin} -> :erlang.binary_to_term(bin)
          :not_found -> %{}
        end

      updated = Map.update(current, {user_id, username}, 1, &(&1 + 1))
      :rocksdb.put(db, key, :erlang.term_to_binary(updated), [])
    end)
  end

  @doc """
  Retrieves the leaderboard for a chat.
  """
  def get_leaderboard(chat_id) do
    with_db(fn db ->
      key = "leaderboard:#{chat_id}"

      case :rocksdb.get(db, key, []) do
        {:ok, bin} -> :erlang.binary_to_term(bin)
        :not_found -> %{}
      end
    end)
  end

  @doc """
  Resets all stored data.
  """
  def reset_all do
    with_db(fn db ->
      {:ok, iterator} = :rocksdb.iterator(db, [])
      delete_all_entries(db, iterator, :first)
    end)
  end

  defp delete_all_entries(db, iterator, action) do
    case :rocksdb.iterator_move(iterator, action) do
      {:ok, key, _} ->
        :rocksdb.delete(db, key, [])
        delete_all_entries(db, iterator, :next)

      _ ->
        :ok
    end
  end
end
