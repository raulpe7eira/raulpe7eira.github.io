defmodule Site.Resume.EducationTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Education

  @valid %{
    "school" => "Centro Universitário da Cidade",
    "url" =>
      "https://en.wikipedia.org/wiki/Centro_Universit%C3%A1rio_da_Cidade_do_Rio_de_Janeiro",
    "closed_in" => 2014,
    "degree" => %{"en" => "Undergraduate", "pt" => "Graduação"},
    "field_of_study" => %{
      "en" => "Technologist in Data Processing",
      "pt" => "Tecnólogo em Processamento de Dados"
    },
    "started_on" => "1998-01-01",
    "finished_on" => "2001-09-01"
  }

  describe "changeset/2" do
    test "accepts a complete education" do
      assert changeset(@valid).valid?
    end

    test "accepts a school that still exists" do
      assert changeset(Map.delete(@valid, "closed_in")).valid?
    end

    test "rejects finishing before starting" do
      assert %{finished_on: ["must not be before started_on"]} =
               errors(Map.put(@valid, "finished_on", "1997-01-01"))
    end

    test "requires a degree" do
      assert %{degree: ["can't be blank"]} = errors(Map.delete(@valid, "degree"))
    end
  end

  defp changeset(attrs), do: Education.changeset(%Education{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
