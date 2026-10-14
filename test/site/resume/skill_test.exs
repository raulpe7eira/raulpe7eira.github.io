defmodule Site.Resume.SkillTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Skill

  describe "changeset/2" do
    test "accepts a type key and items" do
      assert changeset(%{"type" => "practices", "items" => ["Scrum", "Kanban"]}).valid?
    end

    test "requires at least one item" do
      assert %{items: [_ | _]} = errors(%{"type" => "practices", "items" => []})
    end

    test "rejects repeated items" do
      assert %{items: ["has repeated items: Scrum"]} =
               errors(%{"type" => "practices", "items" => ["Scrum", "Scrum"]})
    end

    test "rejects a type that is not a key" do
      assert %{type: ["has invalid format"]} =
               errors(%{"type" => "Practices", "items" => ["Scrum"]})
    end
  end

  defp changeset(attrs), do: Skill.changeset(%Skill{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
