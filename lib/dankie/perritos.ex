defmodule Dankie.Perritos do
  use Tesla
  require Logger
  plug(Tesla.Middleware.BaseUrl, "https://dog.ceo/api/breeds/image")

  ## TODO:
  ## 1. Enable advanced tags
  ## 2. Periodically clean-up images
  ## 3. Consider making this a GenServer that has an image pre-cached.

  def random_dog do
    with {:ok, %Tesla.Env{body: json}} <- get("/random"),
         {:ok, %{"message" => img_link}} <- Jason.decode(json) do
      {:ok, img_link}
    else
      {:error, err} ->
        Logger.error("Got error while trying to reach cats API: #{inspect(err)}")
        :error
    end
  end
end
