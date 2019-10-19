defmodule Fluex.Supervisor do
  @moduledoc false
  use Supervisor
  alias Fluex.FluentNIF
  alias Fluex.Resources

  @default_priv "priv/fluex"

  @doc """
  Starts the translator supervisor.
  """
  def start_link(translator, locales, resources, opts) do
    sup_opts = if name = Keyword.get(opts, :name, translator), do: [name: name], else: []

    Supervisor.start_link(
      __MODULE__,
      {name, translator, locales, resources, opts},
      sup_opts
    )
  end

  ## Callbacks

  @doc false
  def init({name, translator, locales, resources, opts}) do
    Enum.map(locales, fn locale ->
      merged = Resources.merge_resources(translator, locale, resources)
      bundle = FluentNIF.new(locale, merged)
    end)
  end
end
