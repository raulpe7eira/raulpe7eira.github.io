defmodule Site.Resume.TranslatedTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Translated

  describe "changeset/2" do
    test "accepts English and Portuguese text" do
      assert changeset(%{"en" => "Founder", "pt" => "Fundador"}).valid?
    end

    test "requires the English text" do
      assert %{en: ["can't be blank"]} = errors(%{"pt" => "Fundador"})
    end

    test "requires the Portuguese text" do
      assert %{pt: ["can't be blank"]} = errors(%{"en" => "Founder"})
    end
  end

  defp changeset(attrs), do: Translated.changeset(%Translated{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
