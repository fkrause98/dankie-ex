defmodule Dankie.Dolar do
  require Logger
  import Dankie.Troesmas

  @type exchange_rate :: %{
          required(String.t()) => String.t() | float() | String.t(),
          required(:casa) => String.t(),
          required(:compra) => float(),
          required(:fechaActualizacion) => String.t(),
          required(:moneda) => String.t(),
          required(:nombre) => String.t(),
          required(:venta) => float()
        }

  @url "https://dolarapi.com/v1/dolares"
  @spec fetch_data() :: {:ok | :error, [exchange_rate()]}
  def fetch_data() do
    with {:ok, %{body: response}} <- Tesla.get(@url),
         {:ok, dollars} <- Jason.decode(response) do
      {:ok,
       dollars
       |> Enum.map(&raw_map_to_typed/1)}
    else
      err ->
        Logger.error("Got error while trying to fetch dolar api: #{inspect(err)}")
        {:error, :error_dolar_api}
    end
  end

  @spec prepare_msg_text({:ok | :error, [exchange_rate()]}) :: String.t()
  def prepare_msg_text({:ok, rates}) do
    rates
    |> Enum.map(&format_single_exchange_rate/1)
    |> Enum.join("\n")
  end

  def prepare_msg_text({:error, _}), do: troesmizar("No se pudo esta vez, intentá más tarde")

  @spec format_single_exchange_rate(exchange_rate()) :: String.t()
  def format_single_exchange_rate(rate) do
    """
    Dólar #{rate.nombre}
    Compra: #{rate.compra}
    Venta: #{rate.venta}
    Fecha de Actualización: #{rate.fechaActualizacion |> DateTime.from_iso8601() |> then(fn {:ok, date, 0} -> date end)}
    """
  end

  @spec raw_map_to_typed(map()) :: exchange_rate()
  defp raw_map_to_typed(%{
         "casa" => casa,
         "compra" => compra,
         "fechaActualizacion" => fechaActualizacion,
         "moneda" => moneda,
         "nombre" => nombre,
         "venta" => venta
       }) do
    %{
      casa: casa,
      compra: compra,
      fechaActualizacion: fechaActualizacion,
      moneda: moneda,
      nombre: nombre,
      venta: venta
    }
  end
end
