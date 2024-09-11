defmodule DankieTest do
  use ExUnit.Case
  doctest Dankie

  test "Agregar vacio devuelve mensaje acorde" do
    mocked_update =
      %{
        date: 1_726_026_088,
        text: "",
        from: %{
          id: 257_266_743,
          first_name: "Fran",
          language_code: "en",
          is_bot: false,
          username: "Fra_n98"
        },
        message_id: 14139,
        entities: [%{offset: 0, type: "bot_command", length: 8}],
        chat: %{
          id: 257_266_743,
          type: "private",
          first_name: "Fran",
          username: "Fra_n98"
        }
      }

    assert Dankie.Triggers.agregar(mocked_update)
           |> then(fn {:ok, resp} -> resp end)
           |> String.contains?("Me tenés que pasar un texto")
  end

  test "Agregar sin respuesta devuelve mensaje acorde" do
    mocked_update =
      %{
        date: 1_726_026_290,
        text: "aaaaaa",
        from: %{
          id: 257_266_743,
          first_name: "Fran",
          language_code: "en",
          is_bot: false,
          username: "Fra_n98"
        },
        message_id: 14141,
        entities: [%{offset: 0, type: "bot_command", length: 8}],
        chat: %{
          id: 257_266_743,
          type: "private",
          first_name: "Fran",
          username: "Fra_n98"
        }
      }

    assert Dankie.Triggers.agregar(mocked_update)
           |> then(fn {:ok, resp} -> resp end)
           |> String.contains?("Tenés que responderle a algo")
  end
end
