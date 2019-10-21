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

  Fluex loads `.ftl` files (resources) at compile time.
  These resource files must be available for every locale. The resource paths must be provided
  as compile-time configuration (see "Translator configuration") The directory structure
  could look like this:

      priv/fluex/
      ├── en
      │   ├── second
      │   │   └── resource.ftl
      │   ├── fluex.ftl
      │   └── other.ftl
      └── it
          ├── second
          │   └── resource.ftl
          ├── fluex.ftl
          └── other.ftl

  ## Configuration

  ### `:fluex` configuration

  Fluex uses a similar configuration to [Gettext](https://hexdocs.pm/gettext/Gettext.html#module-configuration)

  It supports the following configuration options:
    * `:default_locale` - see [Module Gettext Configuration](https://hexdocs.pm/gettext/Gettext.html#module-gettext-configuration)

  ### Translator configuration

  A Fluex translator (backend) supports some compile-time options. These options
  can be configured in two ways: either by passing them to `use Fluex` (hence
  at compile time):
      defmodule MyApp.Fluex do
        use Fluex, options
      end
  or by using Mix configuration, configuring the key corresponding to the
  backend in the configuration for your application:
      # For example, in config/config.exs
      config :my_app, MyApp.Fluex, options
  Note that the `:otp_app` option (an atom representing an OTP application) has
  to always be present and has to be passed to `use Fluex` because it's used
  to determine the application to read the configuration of (`:my_app` in the
  example above); for this reason, `:otp_app` can't be configured via the Mix
  configuration. This option is also used to determine the Fluex resources.
  The following is a comprehensive list of supported options:
    * `:dir` - a string representing the directory where translations will be
      searched. The directory is relative to the directory of the application
      specified by the `:otp_app` option. By default it's
      `"priv/fluex"`.
    * `:resources` - a list of resources which should be used for translation.
      Pathnames are relative to the locale directory, e.g. `["fluex.ftl", "other.ftl", "second/resource.ftl"]`.
      By default, it uses the opt app name with a `.ftl` extension, e.g. `["my_app.ftl"]`.
    * `:locales` - a list of requested locales to be considered for the application. During
      compile time the list is compared with available locales. Only locales available in
      both lists are considered. By default, all available locales are considered.

  ### Fluex API

  Fluex provides a `translate/3` and `ltranslate/3` macro to your own Fluex module, like `MyApp.Fluex`.
  These macros call the `translate/3` and `ltranslate/3` functions from the `Fluex` module
  A simple example is:

      defmodule MyApp.Fluex do
        use Fluex, otp_app: :my_app
      end

      Fluex.put_locale(MyApp.Fluex, "pt_BR")

      msgid = "Hello"
      MyApp.Fluex.translate(msgid, %{user: "mundo"})
      #=> "Olá \u{2068}mundo\u{2069}"

      MyApp.Fluex.ltranslate("en", msgid, %{user: "world"})
      #=> "Hello \u{2068}world\u{2069}"


  The FSI/PDI isolation marks ensure that the direction of
  the text from the variable is not affected by the translation.
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
