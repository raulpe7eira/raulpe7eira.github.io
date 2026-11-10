defmodule Site.Resume.RecommendationTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Recommendation

  @valid %{
    "name" => "Gerson Scanapieco",
    "url" => "https://www.linkedin.com/in/gerson-scanapieco-7b202248",
    "relationship" => "same_team",
    "given_on" => "2019-01-07",
    "text" => "Working with Raul was an excellent experience."
  }

  describe "changeset/2" do
    test "accepts a LinkedIn recommendation" do
      assert changeset(@valid).valid?
    end

    test "rejects an unknown relationship" do
      assert %{relationship: ["is invalid"]} = errors(Map.put(@valid, "relationship", "friend"))
    end

    test "requires the text" do
      assert %{text: ["can't be blank"]} = errors(Map.delete(@valid, "text"))
    end

    test "requires an https URL" do
      assert %{url: ["must be an https URL"]} =
               errors(Map.put(@valid, "url", "http://linkedin.com/in/someone"))
    end

    test "shows it on the site by default" do
      refute Ecto.Changeset.get_field(changeset(@valid), :hidden)
    end
  end

  defp changeset(attrs), do: Recommendation.changeset(%Recommendation{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
