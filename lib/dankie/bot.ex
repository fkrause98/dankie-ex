defmodule Dankie.Bot do
  @bot :dankie
  require Logger
  alias ExGram.Model.{BotCommand, Update}

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  middleware(ExGram.Middleware.IgnoreUsername)

  command("start")

  def bot(), do: @bot

  def init(opts) do
    {:ok, _} = ExGram.get_me(token: opts[:token])

    {:ok, true} =
      ExGram.set_my_commands(
        [%BotCommand{command: "agregar", description: "Agregar un trigger local"}],
        token: opts[:token]
      )

    :ok
  end

  def handle({:command, :start, msg}, context) do
    IO.inspect(msg)
    answer(context, "Hi!")
  end

  def handle({:command, "agregar", update}, context) do
    {:ok, response} = Dankie.Triggers.agregar(update)
    answer(context, response)
  end

  def handle({:command, "listar", msg}, context) do
    state = GenServer.call(Dankie.Agregar, {:listar, msg, context})
    answer(context, Enum.join(state, "\n"))
  end

  def handle({:command, unknown, _update}, context) do
    Logger.warn("Unknown comand #{unknown} received...")
  end

  def handle({:text, _, _}, context) do
  end
end
