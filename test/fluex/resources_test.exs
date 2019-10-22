defmodule Fluex.ResourcesTest do
  use ExUnit.Case
  alias FluexTest.TranslatorWithMultipleResources, as: Translator
  alias Fluex.Resources

  test "merge_resources/3 merges all resources to build one bundle" do
    merged = Resources.merge_resources(Translator, "en", ["test.ftl", "second/second.ftl"])
    assert merged =~ "tabs-close-button"
    assert merged =~ "second-level"
  end

  test "build_resources/3 loads resource files and returns a list of ftl funtions" do
    assert [
             {_, _, [{:ftl, [context: Fluex.Resources], ["en", "test.ftl"]}, [_]]},
             {_, _, [{:ftl, [context: Fluex.Resources], ["en", "second/second.ftl"]}, [_]]}
           ] =
             Resources.build_resources(Translator.__fluex__(:dir), "en", [
               "test.ftl",
               "second/second.ftl"
             ])
  end
end
