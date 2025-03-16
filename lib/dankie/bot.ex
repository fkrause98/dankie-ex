defmodule Dankie.Bot do
  @bot :dankie
  require Logger
  alias ExGram.Model.{BotCommand, Message, Chat}
  alias Dankie.Troesmas

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

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, "agregar", update}, context) do
    {:ok, response} = Dankie.Triggers.add_trigger(update)
    answer(context, response)
  end

  def handle({:command, "listar", msg = %Message{}}, context) do
    {:ok, response} = Dankie.Triggers.list_triggers(msg)
    answer(context, response)
  end

  def handle({:command, "borrar", msg = %Message{}}, context) do
    {:ok, res} = Dankie.Triggers.delete_trigger(msg)
    answer(context, res)
  end

  def handle({:command, "dolar", _msg}, context) do
    response =
      Dankie.Dolar.fetch_data()
      |> Dankie.Dolar.prepare_msg_text()

    answer(
      context,
      response
    )
  end

  def handle({:command, "ruleta", msg = %Message{chat: %Chat{id: id}}}, context) do
    case Dankie.Ruleta.Supervisor.advance_game(id) do
      {:error, :game_not_found} ->
        {:ok, _pid} = Dankie.Ruleta.Supervisor.new_game(id)

        answer(
          context,
          "Bala cargada, sale un jueguito?"
        )

      :empty ->
        answer(
          context,
          "💦🔫 Te salvaste esta vez. Que pruebe otro."
        )

      :shoot ->
        answer(
          context,
          "💥🔫 Se re-regaló."
        )
    end
  end

  def handle({:command, unknown, _update}, _context) do
    Logger.info("Unknown comand #{unknown} received, ignoring...")
  end

  def handle({:text, text, msg = %Message{chat: chat}}, context) do
    # Check if we have to dispatch 'La Pole'
    if Dankie.Pole.should_congratulate?(chat.id) do
      ExGram.send_message(
        chat.id,
        "@#{msg.from.username} ganastes la pole negri, bien ahí",
        bot: @bot
      )
    end

    case Dankie.Triggers.check_trigger_match(text, chat.id) do
      {:ok, trigger_msg_id} ->
        {:ok, _} =
          ExGram.copy_message(chat.id, chat.id, trigger_msg_id, bot: @bot, caption: "")

      {:error, _} ->
        nil
    end
  end

  def handle(unknown_update, _context) do
    Logger.warn("Unknown update received, ignoring. Content is: #{inspect(unknown_update)} ")
  end
end
