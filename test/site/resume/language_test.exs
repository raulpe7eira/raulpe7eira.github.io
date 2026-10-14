defmodule Site.Resume.LanguageTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Language

  @valid %{
    "name" => %{"en_us" => "Spanish", "pt_br" => "Espanhol"},
    "proficiency" => "elementary"
  }

  describe "changeset/2" do
    test "accepts a LinkedIn proficiency level" do
      assert changeset(@valid).valid?
    end

    test "rejects an unknown proficiency level" do
      assert %{proficiency: ["is invalid"]} = errors(Map.put(@valid, "proficiency", "fluent"))
    end

    test "requires the name in both languages" do
      assert %{name: %{pt_br: ["can't be blank"]}} =
               errors(Map.put(@valid, "name", %{"en_us" => "Spanish"}))
    end
  end

  defp changeset(attrs), do: Language.changeset(%Language{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
