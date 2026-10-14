defmodule Site.LabelsTest do
  use ExUnit.Case, async: true

  alias Site.Labels
  alias Site.Locale

  describe "month_year/1" do
    test "labels every month in English" do
      assert months(:en) == ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
    end

    test "labels every month in Portuguese" do
      assert months(:pt) == ~w(Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez)
    end

    test "puts the year after the month" do
      assert in_lang(:en, fn -> Labels.month_year(~D[2025-10-01]) end) == "Oct 2025"
    end
  end

  describe "present/0" do
    test "is Present in English" do
      assert in_lang(:en, &Labels.present/0) == "Present"
    end

    test "is Atual in Portuguese" do
      assert in_lang(:pt, &Labels.present/0) == "Atual"
    end
  end

  describe "work_mode/1" do
    test "labels every work mode" do
      assert in_lang(:pt, fn -> Enum.map([:remote, :hybrid, :on_site], &Labels.work_mode/1) end) ==
               ["Remoto", "Híbrido", "Presencial"]
    end

    test "is nil without a work mode" do
      assert Labels.work_mode(nil) == nil
    end
  end

  describe "skill/1" do
    test "labels every skill group" do
      types = [:ai, :ai_coding, :programming, :frameworks, :data, :observability, :practices]

      assert in_lang(:en, fn -> Enum.map(types, &Labels.skill/1) end) == [
               "AI",
               "AI coding assistants",
               "Programming",
               "Frameworks",
               "Data and messaging",
               "Observability and infra",
               "Practices"
             ]
    end
  end

  describe "proficiency/1" do
    test "labels every proficiency" do
      levels = [
        :elementary,
        :limited_working,
        :professional_working,
        :full_professional,
        :native_or_bilingual
      ]

      assert in_lang(:en, fn -> Enum.map(levels, &Labels.proficiency/1) end) == [
               "elementary",
               "limited working",
               "professional",
               "full professional",
               "native"
             ]
    end
  end

  describe "reference_group/1" do
    test "labels clients and projects" do
      assert in_lang(:pt, fn -> Enum.map([:clients, :projects], &Labels.reference_group/1) end) ==
               ["Clientes", "Projetos"]
    end
  end

  defp months(lang) do
    in_lang(lang, fn ->
      for month <- 1..12 do
        2000 |> Date.new!(month, 1) |> Labels.month_year() |> String.slice(0, 3)
      end
    end)
  end

  defp in_lang(lang, fun), do: Locale.with_locale(lang, fun)
end
