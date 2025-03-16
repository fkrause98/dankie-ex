defmodule Dankie.Pole do
  use Agent

  @timezone "America/Argentina/Buenos_Aires"

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Checks if the chat should be congratulated for the first message of the day.
  """
  def should_congratulate?(chat_id) do
    {:ok, now} = DateTime.now(@timezone)
    today = DateTime.to_date(now)

    Agent.get_and_update(__MODULE__, fn state ->
      case state[chat_id] do
        ^today ->
          {false, state}

        _ ->
          {true, Map.put(state, chat_id, today)}
      end
    end)
  end

  @doc """
  Resets the state (for testing or manual resets).
  """
  def reset_state do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end
end
