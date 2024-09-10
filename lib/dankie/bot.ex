defmodule Dankie.Bot do
  @bot :dankie

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  middleware(ExGram.Middleware.IgnoreUsername)

  command("start")

  def bot(), do: @bot

  def init(opts) do
    # {:ok, true} = ExGram.set_my_description(description: "Elixir dankie!", bot: opts[:bot])
    # true = ExGram.set_my_name!(name: "Elixir dankie!", token: opts[:token])
    {:ok, _} = ExGram.get_me(token: opts[:token])

    {:ok, true} =
      Dankie.Agregar.provides()
      |> ExGram.set_my_commands(token: opts[:token])

    :ok
  end

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, "agregar", msg}, context) do
    IO.inspect("CASTING")
    :ok = GenServer.cast(Dankie.Agregar, {:agregar, msg, context})
  end

  def handle({:command, "listar", msg}, context) do
    state = GenServer.call(Dankie.Agregar, {:listar, msg, context})
    answer(context, Enum.join(state, "\n"))
  end

  def handle({:text, _, _}, context) do
  end
end
