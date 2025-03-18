defmodule Dankie.Gatitos do
  use Tesla
  require Logger
  plug(Tesla.Middleware.BaseUrl, "https://cataas.com")

  ## TODO:
  ## 1. Enable advanced tags
  ## 2. Enable gifs send
  ## 3. Periodically clean-up images

  def random_cat do
    with {:ok, %Tesla.Env{body: img}} <- get("/cat"),
         img_id = Enum.random(1..1_000_000),
         img_path = "/tmp/cat_#{img_id}.jpg",
         :ok <- File.write(img_path, img) do
      {:ok, img_path}
    else
      {:error, err} ->
        Logger.error("Got error while trying to reach cats API: #{inspect(err)}")
        :error
    end
  end

  def random_cat_gif do
    with {:ok, %Tesla.Env{body: img}} <- get("/cat/gif"),
         img_id = Enum.random(1..1_000_000),
         img_path = "/tmp/cat_#{img_id}.gif",
         :ok <- File.write(img_path, img) do
      {:ok, img_path}
    else
      {:error, err} ->
        Logger.error("Got error while trying to reach cats API: #{inspect(err)}")
        :error
    end
  end
end
