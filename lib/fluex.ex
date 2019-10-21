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

  require Fluex.Compiler
  alias Fluex.FluentNIF

  @doc false
  defmacro __using__(opts) do
    quote do
      @fluex_opts unquote(opts)
      @before_compile Fluex.Compiler
    end
  end

  def child_spec(translator, opts) do
    %{
      id: translator,
      start: {translator, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(translator, opts \\ []) do
    Fluex.Supervisor.start_link(
      translator,
      opts
    )
  end

  def translate(translator, id, bindings \\ %{}) do
    ltranslate(translator, get_locale(translator), id, bindings)
  end

  def ltranslate(translator, locale, id, bindings \\ %{}) do
    bundles = Fluex.Registry.lookup(translator)
    locale = Map.get(bundles, locale)
    fallback = Map.get(bundles, translator.__fluex__(:default_locale))

    cond do
      locale && FluentNIF.has_message?(locale, id) ->
        FluentNIF.format_pattern(locale, id, stringify(bindings))

      fallback && FluentNIF.has_message?(fallback, id) ->
        FluentNIF.format_pattern(fallback, id, stringify(bindings))

      true ->
        raise(
          RuntimeError,
          "bundles in translator #{translator} do no contain a message with id: #{id}"
        )
    end
  end

  defp stringify(bindings) when is_map(bindings) do
    Map.new(bindings, fn
      {key, val} -> {to_string(key), to_string(val)}
    end)
  end

  def __fluex__(:default_locale) do
    # If this is not set by the user, it's still set in mix.exs (to "en").
    Application.fetch_env!(:fluex, :default_locale)
  end

  def get_locale(translator \\ Fluex) do
    with nil <- Process.get(translator),
         nil <- Process.get(Fluex) do
      translator.__fluex__(:default_locale)
    end
  end

  def put_locale(translator \\ Fluex, locale)

  def put_locale(translator, locale) when is_binary(locale),
    do: Process.put(translator, locale)

  def put_locale(_translator, locale),
    do: raise(ArgumentError, "put_locale/1 only accepts binary locales, got: #{inspect(locale)}")
end
