defmodule Dankie.Dolar.Fetcher do
  @two_minutes_in_ms 2 * 60 * 1000
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    state =
      case Dankie.Dolar.fetch_data() do
        {:ok, dollars_json} ->
          dollars_json

        _ ->
          %{}
      end

    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_dollar_data, state) do
    state =
      case Dankie.Dolar.fetch_data() do
        {:ok, dollars_json} ->
          dollars_json

        _ ->
          state
      end

    schedule_work()
    {:noreply, state}
  end

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  defp schedule_work() do
    Process.send_after(self(), :fetch_dollar_data, @two_minutes_in_ms)
  end
end
