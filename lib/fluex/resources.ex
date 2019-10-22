defmodule Fluex.Resources do
  def merge_resources(backend, locale, resources) do
    Enum.map(resources, &backend.ftl(locale, &1))
    |> Enum.join("\n")
  end

  def build_resources(dir, locale, resources) do
    files = resources_in_dir(Path.join(dir, locale), resources)

    Enum.map(files, &create_ftl_function_from_file(locale, resource_from_path(dir, &1), &1))
  end

  defp resources_in_dir(dir, resources) do
    resources
    |> Enum.map(fn path ->
      Path.join(dir, path)
    end)
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
end
