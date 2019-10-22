defmodule FluexTest do
  use ExUnit.Case
  doctest Fluex

  defmodule Translator do
    use Fluex,
      otp_app: :fluex_test,
      dir: "test/resources",
      resources: ["test.ftl"],
      locales: ["en", "de", "it"]
  end

  defmodule TranslatorWithMultipleResources do
    use Fluex,
      otp_app: :fluex_test,
      dir: "test/resources",
      resources: ["test.ftl", "second/second.ftl"]
  end

  defmodule TranslatorWithDefaultConfig do
    use Fluex,
      otp_app: :fluex_test
  end

  setup_all do
    {:ok, _} = Translator.start_link()
    {:ok, _} = TranslatorWithDefaultConfig.start_link()
    :ok
  end

  describe "get_locale/1 and set_locale/1" do
    test "default locale/fallback is \"en\"" do
      assert Fluex.get_locale() === "en"
      assert Fluex.get_locale(Translator) === "en"
    end

    test "sets and returns locale" do
      Fluex.put_locale(Translator, "it")
      assert Fluex.get_locale(Translator) === "it"
    end

    test "only affects the provided translator" do
      Fluex.put_locale(Translator, "it")
      assert Fluex.get_locale(Translator) == "it"
      assert Fluex.get_locale(TranslatorWithDefaultConfig) == "en"
      assert Fluex.get_locale() == "en"
    end

    test "global locale only affects translators that have no specific locale" do
      Fluex.put_locale(Translator, "de")
      Fluex.put_locale("it")
      assert Fluex.get_locale() == "it"
      assert Fluex.get_locale(Translator) == "de"
      assert Fluex.get_locale(TranslatorWithDefaultConfig) == "it"
    end

    test "only accepts binary locale" do
      assert_raise ArgumentError, fn ->
        Fluex.put_locale(:it)
      end
    end
  end

  describe "translate/3" do
    test "returns message for id and locale" do
      assert Translator.ltranslate("en", "tabs-close-tooltip", %{tabCount: 5}) ===
               "Close \u{2068}5\u{2069} tabs"

      assert Translator.ltranslate("it", "tabs-close-tooltip", %{tabCount: 2}) ===
               "Chiudi \u{2068}2\u{2069} schede"

      assert TranslatorWithDefaultConfig.translate("hello", %{world: "World"}) ===
               "Hello \u{2068}World\u{2069}"
    end

    test "returns fallback to default locale if message is not translated" do
      assert Translator.ltranslate("it", "not-translated") ===
               "Only available in en"
    end
  end
end
