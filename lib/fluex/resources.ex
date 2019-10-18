defmodule Fluex.Resources do
  require Logger

  @default_priv "priv/fluex"

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

    priv = Keyword.get(opts, :priv, @default_priv)
    translations_dir = Application.app_dir(otp_app, priv)
    resources = Keyword.get(opts, :resources, ["#{otp_app}.ftl"])
    requested_locales = Keyword.get(opts, :requested, [])
    known_locales = known_locales(translations_dir)

    default_locale =
      opts[:default_locale] || quote(do: Application.fetch_env!(:fluex, :default_locale))

    resolved_locales = resolve_locales(known_locales, requested_locales)

    quote do
      def __fluex__(:priv), do: unquote(priv)
      def __fluex__(:locales), do: unquote(resolved_locales)
      def __fluex__(:default_locale), do: unquote(default_locale)
      def __fluex__(:resources), do: unquote(resources)
    end

    for locale <- requested_locales do
      quote do
        unquote(build_ftls(translations_dir, locale, resources, opts))
      end
    end
  end

  def build_ftls(dir, locale, resources, opts) do
    files = resources_in_dir(Path.join(dir, locale), resources)

    Enum.map(files, &create_ftl_function_from_file(locale, resource_from_path(dir, &1), &1))
  end

  defp resources_in_dir(dir, resources) do
    resources = "{#{Enum.join(resources, ",")}}"

    dir
    |> Path.join(resources)
    |> Path.wildcard()
  end

  defp resource_from_path(root, path) do
    path
    |> Path.relative_to(root)
    |> Path.split()
    # drop locale identifier e.g. in {locale}/resource.ftl
    |> Enum.drop(1)
    |> Path.join()
  end

  defp create_ftl_function_from_file(locale, resource, path) do
    quote do
      def ftl(unquote(locale), unquote(resource)) do
        unquote(File.read!(path))
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

  defp resolve_locales(available, requested) do
    MapSet.intersection(Enum.into(available, MapSet.new()), Enum.into(requested, MapSet.new()))
    |> MapSet.to_list()
  end
end
