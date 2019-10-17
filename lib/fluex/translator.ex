defmodule Fluex.Translator do
  use GenServer
  alias Fluex.FluentNIF, as: Fluent

  def start_link(config) do
    translations =
      config[:translations]
      |> Map.new(fn {locale, path} ->
        {locale, File.read!(path)}
      end)

    translators =
      config[:translators]
      |> Map.new(fn {locale, fallback} ->
        {locale,
         {Fluent.new(Atom.to_string(locale), translations[locale]),
          Fluent.new(Atom.to_string(fallback), translations[fallback])}}
      end)

    GenServer.start_link(__MODULE__, translators, name: __MODULE__)
  end

  def translate(name \\ __MODULE__, locale, id, args) do
    GenServer.call(name, {:get, locale, id, args})
  end

  @impl true
  def init(bundles) do
    {:ok, bundles}
  end

  @impl true
  def handle_call({:get, locale, id, args}, _from, state) do
    {:reply, get_fluent_msg(state[locale], id, args), state}
  end

  defp get_fluent_msg({locale, fallback}, id, args) do
    cond do
      Fluent.has_message?(locale, id) ->
        {:ok, Fluent.format_pattern(locale, id, stringify(args))}

      Fluent.has_message?(fallback, id) ->
        {:ok, Fluent.format_pattern(fallback, id, stringify(args))}

      true ->
        {:error, :not_found}
    end
  end

  defp get_fluent_msg(nil, _id, _args) do
    {:error, :not_supported}
  end

  defp stringify(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      item -> item
    end)
  end
end
