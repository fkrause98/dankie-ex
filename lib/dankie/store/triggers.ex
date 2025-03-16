defmodule Dankie.Store.Triggers do
  require Logger
  @triggers_table_prefix "chat_trigger_table"

  defp table_path_for_chat_id(chat_id),
    do: ~c"./store/#{@triggers_table_prefix}_#{chat_id}"

  defp table_name_for_chat_id(chat_id),
    do: ~c"#{@triggers_table_prefix}_#{chat_id}"

  defp open_chat_table(chat_id) do
    table_path =
      chat_id
      |> table_path_for_chat_id

    table_name =
      chat_id
      |> table_name_for_chat_id

    :dets.open_file(table_name, file: table_path)
  end

  @spec store_trigger(Regex.t(), integer(), integer()) :: :ok | {:error, term()}
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

  @spec traverse_triggers_table(integer(), function()) :: :ok | {:error, term()}
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

  def delete_trigger(regex, chat_id) do
    with {:ok, table_name} <- open_chat_table(chat_id) do
      :dets.delete(table_name, regex)
    else
      err ->
        Logger.error(
          "Error while trying to delete a trigger: #{inspect(err)}, parameters: #{regex}, #{chat_id}"
        )
    end
  end
end
