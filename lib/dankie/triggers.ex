defmodule Dankie.Triggers do
  import Dankie.Troesmas

  def add_trigger(%{text: ""}), do: {:ok, troesmizar("Me tenés que pasar un texto")}

  def add_trigger(%{
        text: new_trigger,
        reply_to_message: reply = %ExGram.Model.Message{}
      }) do
    chat_id = reply.chat.id
    msg_id = reply.message_id

    case check_regex(new_trigger) do
      {:ok, _regex} ->
        :ok = Dankie.Store.Triggers.store_trigger(new_trigger, chat_id, msg_id)
        {:ok, troesmizar("Agregado el trigger")}

      {:error, {reason, position}} ->
        {:error, format_error_message(reason, new_trigger, position)}
    end
  end

  def add_trigger(%{}), do: {:ok, troesmizar("Tenés que responderle a algo")}

  defp format_error_message(reason, new_trigger, position) do
    """
    #{troesma()}, arreglá tu reglex:
    *Error:* #{reason}
    #{new_trigger} #{String.duplicate(" ", position)}^
    """
  end

  @spec check_regex(String.t()) :: {:ok, Regex.t()} | {:error, term()}
  defp check_regex(regex) when is_binary(regex) do
    Regex.compile(regex)
  end

  @spec check_trigger_match(String.t(), Int.t()) :: {:ok, String.t()} | {:error, :no_match}
  def check_trigger_match(text, chat_id) when is_binary(text) and is_number(chat_id) do
    regex_matching_fun = fn {pattern, trigger_text} ->
      case Regex.compile(pattern) do
        {:ok, regex} ->
          if Regex.match?(regex, text) do
            {:done, trigger_text}
          else
            :continue
          end

        _ ->
          :continue
      end
    end

    result = Dankie.Store.Triggers.traverse_triggers_table(chat_id, regex_matching_fun)

    case result do
      [{trigger_chat_id, trigger_msg_id} | _] -> {:ok, {trigger_chat_id, trigger_msg_id}}
      _ -> {:error, :no_match}
    end
  end
end
