defmodule Dankie.Triggers do
  import Dankie.Troesmas
  alias ExGram.Model.Message
  use NewRelic.Tracer

  @spec add_trigger(Update.t()) :: {:ok, binary()} | {:error, binary()}
  def add_trigger(%Message{text: ""}), do: {:ok, troesmizar("Me tenés que pasar un texto")}

  def add_trigger(%Message{
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

  @spec check_trigger_match(String.t(), integer()) :: {:ok, integer()} | {:error, :no_match}
  @trace :check_trigger_match
  def check_trigger_match(text, chat_id) when is_binary(text) and is_number(chat_id) do
    NewRelic.add_span_attributes(regex: text, chat_id: chat_id)

    regex_matching_fun = fn {pattern, msg_id} ->
      case Regex.compile(pattern) do
        {:ok, regex} ->
          if Regex.match?(regex, text) do
            {:done, msg_id}
          else
            :continue
          end

        _ ->
          :continue
      end
    end

    case Dankie.Store.Triggers.traverse_triggers_table(chat_id, regex_matching_fun) do
      {:ok, [trigger_msg_id | _]} -> {:ok, trigger_msg_id}
      _ -> {:error, :no_match}
    end
  end

  @spec delete_trigger(Message.t()) :: {:ok, String.t()} | {:error, :no_match}
  def delete_trigger(%Message{text: to_delete, chat: %{id: chat_id}}) do
    case Regex.compile(to_delete) do
      {:ok, _regex} ->
        case Dankie.Store.Triggers.delete_trigger(to_delete, chat_id) do
          :ok ->
            {:ok, troesmizar("Borrado")}

          _err ->
            {:ok, troesmizar("Intenta más tarde")}
        end

      _ ->
        {:ok, troesmizar("Eso no es un regex ni en pedo")}
    end
  end

  @spec list_triggers(Message.t()) :: {:ok, String.t()} | {:error, String.t()}
  def list_triggers(%Message{chat: %{id: chat_id}}) do
    case Dankie.Store.Triggers.traverse_triggers_table(chat_id, &trigger_accumulator/1) do
      {:ok, []} ->
        {:ok, troesmizar("No hay triggers todavía")}

      {:ok, triggers} ->
        response = "Triggers conocidos:\n" <> Enum.join(triggers, "\n")
        {:ok, response}

      {:error, _} ->
        {:ok, troesmizar("Intentá más tarde")}
    end
  end

  defp trigger_accumulator({trigger_text, _}), do: {:done, trigger_text}
end
