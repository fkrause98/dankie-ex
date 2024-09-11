defmodule Dankie.Triggers do
  alias ExGram.Model.{Message, Chat}
  import Dankie.Troesmas

  def agregar(%{text: ""}), do: {:ok, troesmizar("Me tenés que pasar un texto")}

  def agregar(%{text: new_trigger, reply_to_message: %{chat: chat_id, message_id: msg_id}}) do
    case check_regex(new_trigger) do
      {:ok, _} ->
        {:ok, troesmizar("Agregado el trigger")}

      {:error, {reason, position}} ->
        {:ok, format_error_message(reason, new_trigger, position)}
    end
  end

  def agregar(%{}), do: {:ok, troesmizar("Tenés que responderle a algo")}

  defp format_error_message(reason, new_trigger, position) do
    """
    #{troesma()}, arreglá tu reglex:
    *Error:* #{reason}
    #{new_trigger} #{String.duplicate(" ", position)}^
    """
  end

  def check_regex(regex) when is_binary(regex) do
    Regex.compile(regex)
  end
end
