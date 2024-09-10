defmodule Dankie.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Dankie.Worker.start_link(arg)
      # {Dankie.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: Dankie.Router, options: [port: 8000]},
      {Finch, name: MyFinch},
      ExGram,
      Dankie.Agregar,
      {Dankie.Bot,
       [
         method:
           {:webhook,
            [
              url:
                "https://074c-201-231-180-119.ngrok-free.app/telegram/PrBOmHWVIHxEPxuZ2DhP6XKW4t4="
            ]},
         token: System.fetch_env!("BOT_TOKEN")
       ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dankie.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
