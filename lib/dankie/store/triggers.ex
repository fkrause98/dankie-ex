defmodule Dankie.Store.Triggers do
  require Logger
  @triggers_table_prefix "./store/#{Mix.env()}/chat_triggers"

  @moduledoc """
  Module to interface between triggers logic and RocksDB storage.
  Each chat has its own RocksDB instance to store triggers as key-value pairs
  where the key is the trigger text and the value is the associated message ID.
  """

  @spec db_path_for_chat_id(integer()) :: String.t()
  defp db_path_for_chat_id(chat_id),
    do: @triggers_table_prefix <> "_#{chat_id}"

  defp db_options do
    [
      create_if_missing: true,
      paranoid_checks: true
    ]
  end

  @spec open_chat_db(integer()) :: {:ok, reference()} | {:error, term()}
  defp open_chat_db(chat_id) do
    db_path = chat_id |> db_path_for_chat_id
    File.mkdir_p!(Path.dirname(db_path))

    db_path
    |> String.to_charlist()
    |> :rocksdb.open(db_options())
  end

  @doc """
  Stores a trigger in the chat's RocksDB database.
  """
  @spec store_trigger(String.t(), integer(), integer()) :: :ok | {:error, term()}
  def store_trigger(new_trigger, chat_id, msg_id) do
    case open_chat_db(chat_id) do
      {:ok, db} ->
        try do
          encoded = :erlang.term_to_binary(msg_id)
          :rocksdb.put(db, new_trigger, encoded, [])
        after
          :rocksdb.close(db)
        end

      error ->
        log_error(error, "store_trigger", [new_trigger, chat_id, msg_id])
        error
    end
  end

  @doc """
  Iterates over all triggers in a chat's database, applying the given function.
  """
  @spec traverse_triggers_table(integer(), function()) :: {:ok, list()} | {:error, term()}
  def traverse_triggers_table(chat_id, traverse_fun) when is_function(traverse_fun) do
    with {:ok, db} <- open_chat_db(chat_id),
         {:ok, iterator} <- :rocksdb.iterator(db, []) do
      results = iterate_and_apply(iterator, traverse_fun, :first, [])
      :rocksdb.iterator_close(iterator)
      :rocksdb.close(db)
      {:ok, results}
    else
      error ->
        log_error(error, "traverse_triggers_table", [chat_id])
        error
    end
  end

  defp iterate_and_apply(iterator, fun, action, acc) do
    case :rocksdb.iterator_move(iterator, action) do
      {:ok, key, value_bin} ->
        value = :erlang.binary_to_term(value_bin)

        case fun.({key, value}) do
          :continue ->
            iterate_and_apply(iterator, fun, :next, acc)

          {:done, result} ->
            iterate_and_apply(iterator, fun, :next, [result | acc])
        end

      {:error, :invalid_iterator} ->
        Enum.reverse(acc)

      error ->
        Logger.error("Iteration error: #{inspect(error)}")
        Enum.reverse(acc)
    end
  end

  @doc """
  Deletes a trigger from the chat's database.
  """
  @spec delete_trigger(String.t(), integer()) :: :ok | {:error, term()}
  def delete_trigger(regex, chat_id) do
    case open_chat_db(chat_id) do
      {:ok, db} ->
        try do
          :rocksdb.delete(db, regex, [])
        after
          :rocksdb.close(db)
        end

      error ->
        log_error(error, "delete_trigger", [regex, chat_id])
        error
    end
  end

  defp log_error(error, function, params) do
    Logger.error("Error in #{function}: #{inspect(error)}, Params: #{inspect(params)}")
  end
end
