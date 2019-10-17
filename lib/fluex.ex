defmodule Fluex do
  @moduledoc """
  The `Fluex` module provides a localization system for natural-sounding translations using [fluent-rs](https://github.com/projectfluent/fluent-rs).
  Fluex uses [NIFs](https://github.com/rusterlium/rustler) to make calls to fluent-rs.

  ## Installation

  Add `Fluex` to your list of dependencies in mix.exs:

    def deps do
      [{:fluex, ">= 0.0.0"}]
    end

  Then run mix deps.get to fetch the new dependency.

  ## Translations

  Translations are stored inside Fluent files, with a `.ftl`
  extension. For example, this is a snippet from a .ftl file:

    # Simple things are simple.
    hello-user = Hello, {$userName}!

    # Complex things are possible.
    shared-photos =
        {$userName} {$photoCount ->
            [one] added a new photo
          *[other] added {$photoCount} new photos
        } to {$userGender ->
            [male] his stream
            [female] her stream
          *[other] their stream
        }.

  For more information visit [Project Fluent](https://projectfluent.org/).

  ## Configuration

  Fluex loads `.ftl` files to create the translation bundles. The locales and Fluent files
  can be configured through the `:translations` key of the `:fluex` application:

    config :fluex, translations: [
      en: "locales/en/my_app.ftl",
      es: "locales/es/my_app.ftl"
    ],

  Each translation bundle is configured as `{locale, fallback}` tuples. These
  bundles can be configured through the `:translators` key of the `:fluex` application:

    config :fluex, translators: [{:es, :en}]

  """
  alias Fluex.Translator

  @doc """
  Returns the translated string for a give id. If the translation is not found, the fallback string
  is returned. If the id does not exist `{:error, :not_found}` is returned. If the locale is not supported
  `{:error, :not_supported}` is returned.

  ## Examples

    iex> Fluex.translate(:es, "hello-user", %{userName: "Example User"})
        {:ok, "Hello, Example User!"}

    iex> Fluex.translate(:de, "hello-user", %{userName: "Example User"})
        {:error, :not_supported}
  """
  @spec translate(locale :: atom, id :: binary, attrs :: map()) ::
          {:ok, binary} | {:error, :not_found} | {:error, :not_supported}
  def translate(locale, id, attrs \\ %{}) do
    Translator.translate(locale, id, attrs)
  end
end
