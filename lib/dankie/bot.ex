defmodule Dankie.Bot do
  @bot :dankie
  require Logger
  alias ExGram.Model.{BotCommand, Message, Chat}
  alias Dankie.Troesmas

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  middleware(ExGram.Middleware.IgnoreUsername)

  @command_list [
    %BotCommand{command: "agregar", description: "Agrega como trigger al texto dado"},
    %BotCommand{command: "dolar", description: "Doy una lista de las cotizaciones"},
    %BotCommand{command: "poles", description: "Listar las poles para este chat"},
    %BotCommand{command: "borrar", description: "Borra el trigger en base al texto dado"},
    %BotCommand{command: "listar", description: "Lista los triggers existentes para este chat"},
    %BotCommand{command: "ruleta", description: "Un jueguito muy divertido"},
    %BotCommand{command: "gatito", description: "Mando la foto de un gatito"},
    %BotCommand{command: "gifgatito", description: "Mando un gif de un gatito"},
    %BotCommand{command: "perrito", description: "Mando la foto de un perrito"}
  ]

  command("start")

  def bot(), do: @bot

  def init(opts) do
    {:ok, _} = ExGram.get_me(bot: opts[:bot])

    {:ok, true} =
      ExGram.set_my_commands(
        @command_list,
        bot: opts[:bot]
      )

    :ok
  end

  def handle({:command, "start", _msg}, context) do
    answer(context, "Hola! Podés usar /comandos para saber lo puedo hacer :D")
  end

  def handle({:command, "comandos", _msg}, context) do
    commands_text =
      @command_list
      |> Enum.map(fn cmd ->
        "/#{cmd.command} - #{cmd.description}"
      end)
      |> Enum.join("\n")

    built_in_commands = [
      "/start - Te doy un mensaje de bienvenida",
      "/comandos - Muestra esta lista de comandos"
    ]

    full_text = """
    ¡Hola! Estos son los comandos disponibles:

    #{commands_text}
    #{Enum.join(built_in_commands, "\n")}

    Usá estos comandos escribiendo el símbolo / seguido del nombre del comando. #{Troesmas.troesmizar("Divertite")}
    """

    answer(context, full_text)
  end

  def handle({:command, "agregar", update}, context) do
    {:ok, response} = Dankie.Triggers.add_trigger(update)
    answer(context, response)
  end

  def handle({:command, "poles", %Message{chat: %Chat{id: chat_id}}}, _context) do
    response =
      chat_id
      |> Dankie.Pole.get_leaderboard()
      |> Dankie.Pole.format_leaderboard()

    ExGram.send_message(
      chat_id,
      response,
      disable_notification: true,
      bot: @bot
    )
  end

  def handle({:command, "borrar", msg = %Message{}}, context) do
    {:ok, res} = Dankie.Triggers.delete_trigger(msg)
    answer(context, res)
  end

  def handle({:command, "listar", msg = %Message{}}, context) do
    {:ok, res} = Dankie.Triggers.list_triggers(msg)
    answer(context, res)
  end

  def handle({:command, "dolar", _msg}, context) do
    response =
      Dankie.Dolar.cached_data()
      |> Dankie.Dolar.prepare_msg_text()

    answer(
      context,
      response
    )
  end

  def handle({:command, "ruleta", _msg = %Message{chat: %Chat{id: id}}}, context) do
    case Dankie.Ruleta.advance_game(id) do
      {:error, :game_not_found} ->
        {:ok, _pid} = Dankie.Ruleta.new_game(id)

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

  def handle({:command, "gatito", _msg = %Message{chat: chat}}, context) do
    case Dankie.Gatitos.random_cat() do
      {:ok, image_path} ->
        ExGram.send_photo(chat.id, {:file, image_path}, bot: @bot)

      _err ->
        answer(context, Troesmas.troesmizar("Mmmm, no encontré ningún gatito, intentá más tarde"))
    end
  end

  def handle({:command, "gifgatito", _msg = %Message{chat: chat}}, context) do
    case Dankie.Gatitos.random_cat_gif() do
      {:ok, image_path} ->
        case ExGram.send_animation(chat.id, {:file, image_path}, bot: @bot) do
          {:ok, _} ->
            nil

          err ->
            Logger.error("Got an error while trying to send a picture: #{inspect(err)}")
        end

      _err ->
        answer(context, Troesmas.troesmizar("Mmmm, no encontré ningún gatito, intená más tarde"))
    end
  end

  def handle({:command, "perrito", _msg = %Message{chat: chat}}, context) do
    case Dankie.Perritos.random_dog() do
      {:ok, image_url} ->
        case ExGram.send_photo(chat.id, image_url, bot: @bot) do
          {:ok, _} ->
            nil

          err ->
            Logger.error("Got an error while trying to send a picture: #{inspect(err)}")
        end

      _err ->
        answer(context, Troesmas.troesmizar("Mmmm, no encontré ningún perrito, intená más tarde"))
    end
  end

  def handle({:command, unknown, _update}, _context) do
    Logger.info("Unknown comand #{unknown} received, ignoring...")
  end

  def handle({:text, text, msg = %Message{chat: chat}}, _context) do
    # Check if we have to dispatch 'La Pole'
    case Dankie.Pole.should_congratulate?(chat.id) do
      :already_done ->
        nil

      :must_congratulate ->
        Dankie.Pole.record_winner(chat.id, msg.from)

        ExGram.send_message(
          chat.id,
          "@#{msg.from.username} ganastes la pole negri, bien ahí",
          bot: @bot
        )
    end

    case Dankie.Triggers.check_trigger_match(text, chat.id) do
      {:ok, trigger_msg_id} ->
        case ExGram.copy_message(chat.id, chat.id, trigger_msg_id, bot: @bot, caption: "") do
          {:ok, _} ->
            nil

          err ->
            Logger.error("Got an error while returning a trigger reponse: #{inspect(err)}")
        end

      {:error, _} ->
        nil
    end
  end

  def handle(unknown_update, _context) do
    Logger.warning("Unknown update received, ignoring. Content is: #{inspect(unknown_update)} ")
  end
end
