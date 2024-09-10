defmodule Dankie.Agregar do
  use GenServer
  alias ExGram.Model.BotCommand

  def provides() do
    [
      %BotCommand{
        command: "agregar",
        description: "Agregar un trigger a la dankie"
      }
    ]
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    Process.register(self(), __MODULE__)
    {:ok, []}
  end

  @impl true
  def handle_call({:listar, msg, context}, from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:agregar, msg, context}, state) do
    case msg do
      %{text: ""} -> {:noreply, state}
      %{text: text} -> {:noreply, [text | state]}
    end
  end
end
