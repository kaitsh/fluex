defmodule FluexTest do
  use ExUnit.Case
  doctest Fluex

  defmodule Translator do
    use Fluex,
      otp_app: :fluex,
      dir: "test/resources",
      resources: ["fluex.ftl"],
      requested: ["en", "it"]
  end

  setup_all do
    {:ok, _} = Translator.start_link()
    :ok
  end

  test "translate/3 returns message for id and locale" do
    assert Fluex.translate(Translator, "tabs-close-tooltip", %{tabCount: 5}) ===
             "Close \u{2068}5\u{2069} tabs"

    Fluex.put_locale(Translator, "it")

    assert Fluex.translate(Translator, "tabs-close-tooltip", %{tabCount: 2}) ===
             "Chiudi \u{2068}2\u{2069} schede"
  end

  test "get_locale/1 returns default locale from config" do
    assert Fluex.get_locale() === "en"
    assert Fluex.get_locale(Translator) === "en"
  end
end
