defmodule Site.ResumeViewTest do
  use ExUnit.Case, async: true

  alias Site.Locale
  alias Site.Resume
  alias Site.ResumeView

  setup_all do
    resume = Resume.load!()

    %{
      en: Locale.with_locale(:en, fn -> ResumeView.build(resume, :en) end),
      pt: Locale.with_locale(:pt, fn -> ResumeView.build(resume, :pt) end)
    }
  end

  describe "build/2" do
    test "splits the summary into paragraphs", %{en: view} do
      assert length(view.summary) == 4
    end

    test "picks the location in the language", %{pt: view} do
      assert view.location == "Rio de Janeiro, Brasil"
    end

    test "labels links without the scheme", %{en: view} do
      assert view.linkedin == %{
               url: "https://linkedin.com/in/raulpe7eira",
               label: "linkedin.com/in/raulpe7eira"
             }
    end

    test "shows the display name of a company", %{en: view} do
      assert experience(view, "Supply Midia").name == "Supply Midia"
    end

    test "derives the company logo from the display name", %{en: view} do
      assert experience(view, "Supply Midia").logo == "sq-supply-midia"
    end

    test "joins the location and the work mode", %{en: view} do
      assert experience(view, "Arionkoder").location ==
               "Massachusetts, United States · Remote"
    end

    test "shows an open role as ending at present", %{en: view} do
      assert experience(view, "Arionkoder").period == "Oct 2025 - Present"
    end

    test "translates the months", %{pt: view} do
      assert experience(view, "Arionkoder").period == "Out 2025 - Atual"
    end

    test "spans a company's period over all its roles", %{en: view} do
      assert experience(view, "Jaya Tech").period == "Feb 2018 - Jul 2022"
    end

    test "marks companies that ended up to 2012 as earlier", %{en: view} do
      assert experience(view, "Atos").earlier?
    end

    test "does not mark open companies as earlier", %{en: view} do
      refute experience(view, "R3M Tech").earlier?
    end

    test "keeps the text before the bullets as one paragraph", %{en: view} do
      assert ["As a software engineer at iSeatz" <> _rest] = role(view, "Arionkoder").paragraphs
    end

    test "separates the description bullets without the dash", %{en: view} do
      assert "Improved logs and error messages across the platform" in role(view, "Arionkoder").bullets
    end

    test "groups clients before projects, with labels", %{en: view} do
      assert Enum.map(role(view, "R3M Tech").references, & &1.label) == ["Clients", "Projects"]
    end

    test "derives the client logo from its name", %{en: view} do
      [_clients, projects] = role(view, "R3M Tech").references
      assert hd(projects.items).logo == "cl-arca-fiocruz"
    end

    test "joins degree and field of study", %{pt: view} do
      assert hd(view.educations).degree =~ "Pós-graduação, Ergonomia"
    end

    test "shows the display name of a school", %{en: view} do
      assert hd(view.educations).name == "PUC-Rio"
    end

    test "labels the skill groups", %{pt: view} do
      assert view.skills |> Enum.take(2) |> Enum.map(& &1.label) == [
               "IA",
               "Assistentes de código IA"
             ]
    end

    test "shows each language with its proficiency", %{en: view} do
      assert view.languages == [
               "Portuguese (native)",
               "English (professional)",
               "Spanish (elementary)"
             ]
    end
  end

  describe "slug/1" do
    test "lowercases and joins words with dashes" do
      assert ResumeView.slug("C6 Bank") == "c6-bank"
    end

    test "drops accents" do
      assert ResumeView.slug("Caixa Econômica Federal") == "caixa-economica-federal"
    end

    test "drops punctuation" do
      assert ResumeView.slug("CloudWalk, Inc.") == "cloudwalk-inc"
    end

    test "drops parentheses at the end" do
      assert ResumeView.slug("ARCA (Fiocruz)") == "arca-fiocruz"
    end
  end

  defp experience(view, name), do: Enum.find(view.experiences, &(&1.name == name))
  defp role(view, name), do: view |> experience(name) |> Map.fetch!(:roles) |> hd()
end
