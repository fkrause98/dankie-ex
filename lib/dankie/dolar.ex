defmodule Dankie.Dolar do
  require Logger
  import Dankie.Troesmas
  @two_minutes_in_ms 2 * 60 * 1000

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    state =
      case fetch_data() do
        {:ok, dollars_json} ->
          dollars_json

        _ ->
          %{}
      end

    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_dollar_data, state) do
    state =
      case fetch_data() do
        {:ok, dollars_json} ->
          dollars_json

        _ ->
          state
      end

    schedule_work()
    {:noreply, state}
  end

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  defp schedule_work() do
    Process.send_after(self(), :fetch_dollar_data, @two_minutes_in_ms)
  end

  def cached_data() do
    cached_data = GenServer.call(__MODULE__, :state)
    {:ok, cached_data |> Enum.map(&raw_map_to_typed/1)}
  end

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
  defp fetch_data() do
    with {:ok, %{body: response}} <- Tesla.get(@url),
         {:ok, dollars_json} <- Jason.decode(response) do
      {:ok, dollars_json}
    else
      err ->
        Logger.error("Got error while trying to fetch dolar api: #{inspect(err)}")
        {:error, :error_dolar_api}
    end
  end

  @spec format_single_exchange_rate(exchange_rate()) :: String.t()
  def format_single_exchange_rate(rate) do
    # Format numbers handling both float and integer values
    compra_formatted = format_number(rate.compra)
    venta_formatted = format_number(rate.venta)

    # Parse the UTC date and convert to Buenos Aires timezone
    {:ok, utc_date, _offset} = rate.fechaActualizacion |> DateTime.from_iso8601()
    buenos_aires_date = utc_date |> DateTime.shift_zone!("America/Argentina/Buenos_Aires")
    formatted_date = buenos_aires_date |> Calendar.strftime("%d/%m/%Y %H:%M")

    """
    💵 *Dólar #{rate.nombre}*
    ✅ Compra: $#{compra_formatted}
    💸 Venta: $#{venta_formatted}
    🕒 Actualizado: #{formatted_date} (ART)
    """
  end

  @spec format_number(number()) :: String.t()
  defp format_number(value) when is_integer(value), do: "#{value},00"

  defp format_number(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 2) |> String.replace(".", ",")

  @spec prepare_msg_text({:ok | :error, [exchange_rate()]}) :: String.t()
  def prepare_msg_text({:ok, rates}) do
    header = "📊 *COTIZACIONES DEL DÓLAR* 📊\n"

    body =
      rates
      |> Enum.map(&format_single_exchange_rate/1)
      |> Enum.join("\n")

    footer = "\nDatos obtenidos de dolarapi.com"

    header <> body <> footer
  end

  def prepare_msg_text(_no_data),
    do: troesmizar("❌ No se pudo obtener la información. Intentá más tarde.")

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
