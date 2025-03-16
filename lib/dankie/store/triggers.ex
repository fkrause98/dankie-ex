defmodule Dankie.Store.Triggers do
  require Logger
  @triggers_table_prefix "chat_trigger_table"

  @moduledoc """
  Module to interface between triggers logic
  and the tables that store the regexes.

  The idea here is that we have a table for each chat_id,
  to make sure we don't mix up triggers of different chats.

  Think of the underlying table storage as a mapping of the form
  TriggerText -> MessageId. So, when we want to retrieve triggers
  for a message, we open the table for the chat id that we need,
  and check if one of the existing triggers matches and then
  we make the bot forward the found message id. This
  is a seriously naive implementation, and I think we can do
  better, so we should explore some other options if
  the bot starts to react slowly to incoming messages.

  """

  # Given a chat id, returns the name for its existing or
  # to-be-created table path.
  @spec table_path_for_chat_id(integer()) :: charlist()
  defp table_path_for_chat_id(chat_id),
    do: ~c"./store/#{@triggers_table_prefix}_#{chat_id}"

  # Given a chat id, returns the name for its existing or
  # to-be-created table.
  @spec table_name_for_chat_id(integer()) :: charlist()
  defp table_name_for_chat_id(chat_id),
    do: ~c"#{@triggers_table_prefix}_#{chat_id}"

  # Given a chat id, return the handle for the table it
  # corresponds to.
  @spec open_chat_table(integer()) :: {:ok, binary() | atom} | {:err, term()}
  defp open_chat_table(chat_id) do
    table_path =
      chat_id
      |> table_path_for_chat_id

    table_name =
      chat_id
      |> table_name_for_chat_id

    :dets.open_file(table_name, file: table_path)
  end

  @doc """
  This function will store in the table that matches the given chat_id
  key-value pair which will have as a key the new trigger and as value
  the message id.
  """
  @spec store_trigger(String.t(), integer(), integer()) :: :ok | {:error, term()}
  def store_trigger(new_trigger, chat_id, msg_id) do
    with {:ok, table_name} <- open_chat_table(chat_id),
         :ok <- :dets.insert(table_name, {new_trigger, msg_id}),
         :ok <- :dets.close(table_name) do
      :ok
    else
      err ->
        Logger.error(
          "Could not add trigger! Got error: #{inspect(err)}, parameters: #{new_trigger}, #{chat_id}, #{msg_id}"
        )

        err
    end
  end

  @doc """
  The given function (traverse_fun) will iterate over each key-value pair
  under the matching table for chat_id
  """
  @spec traverse_triggers_table(integer(), function()) :: {:ok, list()} | {:error, term()}
  def traverse_triggers_table(chat_id, traverse_fun) when is_function(traverse_fun) do
    with {:ok, table_name} <- open_chat_table(chat_id),
         traverse_result <- :dets.traverse(table_name, traverse_fun),
         :ok <- :dets.close(table_name) do
      {:ok, traverse_result}
    else
      err ->
        Logger.error(
          "Error while traversing trigger table: #{inspect(err)}, for chat id: #{chat_id}"
        )

        err
    end
  end

  @doc """
  This function will delete the key-value pair that matches
  the given string, under the table for this chat_id.
  """
  @spec delete_trigger(String.t(), integer()) :: :ok | {:error, term()}
  def delete_trigger(regex, chat_id) do
    with {:ok, table_name} <- open_chat_table(chat_id) do
      :dets.delete(table_name, regex)
      :dets.close(table_name)
    else
      err ->
        Logger.error(
          "Error while trying to delete a trigger: #{inspect(err)}, parameters: #{regex}, #{chat_id}"
        )
    end
  end
end
