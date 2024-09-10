defmodule Dankie.Router do
  use Plug.Router

  plug(ExGram.Plug)

  match "/" do
    send_resp(404)
  end
end
