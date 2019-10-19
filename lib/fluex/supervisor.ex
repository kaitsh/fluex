defmodule Fluex.Supervisor do
  @moduledoc false
  use Supervisor
  alias Fluex.FluentNIF
  alias Fluex.Resources

  @default_priv "priv/fluex"

  @doc """
  Starts the translator supervisor.
  """
  def start_link(translator, opts) do
    sup_opts = if name = Keyword.get(opts, :name, translator), do: [name: name], else: []

    Supervisor.start_link(
      __MODULE__,
      {name, translator, opts},
      sup_opts
    )
  end

  ## Callbacks

  @doc false
  def init({name, translator, opts}) do
    locales = translator.__fluex__(:locales)
    resources = translator.__fluex__(:resources)

    meta =
      Map.new(locales, fn locale ->
        merged = Resources.merge_resources(translator, locale, resources)
        bundles = FluentNIF.new(locale, merged)

        {locale, bundles}
      end)

    Fluex.Registry.associate(self(), meta)

    Supervisor.init([], strategy: :one_for_one, max_restarts: 0)
  end
end
