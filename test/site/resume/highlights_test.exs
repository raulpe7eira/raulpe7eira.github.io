defmodule Site.Resume.HighlightsTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Highlights

  describe "changeset/2" do
    test "accepts the English text" do
      assert changeset(%{"en_us" => "Founder of R3M Tech."}).valid?
    end

    test "requires the English text" do
      assert %{en_us: ["can't be blank"]} = errors(%{})
    end
  end

  defp changeset(attrs), do: Highlights.changeset(%Highlights{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
