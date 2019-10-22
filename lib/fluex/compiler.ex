defmodule Fluex.Compiler do
  alias Fluex.Resources

  @default_dir "priv/fluex"

  @doc false
  defmacro __before_compile__(env) do
    compile_time_opts = Module.get_attribute(env.module, :fluex_opts)

    # :otp_app is only supported in "use Fluex" (because we need it to get the Mix config).
    {otp_app, compile_time_opts} = Keyword.pop(compile_time_opts, :otp_app)

    if is_nil(otp_app) do
      # We're using Keyword.fetch!/2 to raise below.
      Keyword.fetch!(compile_time_opts, :otp_app)
    end

    # Override mix config with "use Fluex" config
    mix_config_opts = Application.get_env(otp_app, env.module, [])
    opts = Keyword.merge(mix_config_opts, compile_time_opts)

    translations_dir = Keyword.get(opts, :dir, @default_dir)
    resources = Keyword.get(opts, :resources, ["#{otp_app}.ftl"])

    default_locale =
      opts[:default_locale] || quote(do: Application.fetch_env!(:fluex, :default_locale))

    requested_locales = Keyword.get(opts, :locales, [])
    known_locales = known_locales(translations_dir)
    resolved_locales = resolve_locales(known_locales, requested_locales)

    quote do
      def __fluex__(:dir), do: unquote(translations_dir)
      def __fluex__(:locales), do: unquote(resolved_locales)
      def __fluex__(:default_locale), do: unquote(default_locale)
      def __fluex__(:resources), do: unquote(resources)

      unquote(
        Enum.flat_map(
          resolved_locales,
          &Resources.build_resources(translations_dir, &1, resources)
        )
      )

      def child_spec(opts) do
        Fluex.child_spec(unquote(env.module), opts)
      end

      def start_link(opts \\ []) do
        Fluex.start_link(unquote(env.module), opts)
      end

      def translate!(id, bindings \\ %{}) do
        Fluex.translate!(unquote(env.module), id, bindings)
      end

      def translate(id, bindings \\ %{}) do
        Fluex.translate(unquote(env.module), id, bindings)
      end

      def ltranslate!(locale, id, bindings \\ %{}) do
        Fluex.ltranslate!(unquote(env.module), locale, id, bindings)
      end

      def ltranslate(locale, id, bindings \\ %{}) do
        Fluex.ltranslate(unquote(env.module), locale, id, bindings)
      end
    end
  end

  # Returns all the locales in `translations_dir`
  defp known_locales(translations_dir) do
    case File.ls(translations_dir) do
      {:ok, files} ->
        Enum.filter(files, &File.dir?(Path.join(translations_dir, &1)))

      {:error, :enoent} ->
        []
    end
  end

  defp resolve_locales(available, []) do
    available
  end

  defp resolve_locales(available, requested) do
    MapSet.intersection(Enum.into(available, MapSet.new()), Enum.into(requested, MapSet.new()))
    |> MapSet.to_list()
  end
end
