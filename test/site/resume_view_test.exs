defmodule Site.ResumeViewTest do
  use ExUnit.Case, async: true

  alias Site.Locale
  alias Site.Resume
  alias Site.ResumeView

  setup_all do
    resume = Resume.load!()

    %{
      en_us: Locale.with_locale(:en_us, fn -> ResumeView.build(resume, :en_us) end),
      pt_br: Locale.with_locale(:pt_br, fn -> ResumeView.build(resume, :pt_br) end)
    }
  end

  describe "build/2" do
    test "splits the summary into paragraphs", %{en_us: view} do
      assert length(view.summary) == 4
    end

    test "picks the location in the language", %{pt_br: view} do
      assert view.location == "Rio de Janeiro, Brasil"
    end

    test "labels links without the scheme", %{en_us: view} do
      assert view.linkedin == %{
               url: "https://linkedin.com/in/raulpe7eira",
               label: "linkedin.com/in/raulpe7eira"
             }
    end

    test "shows the display name of a company", %{en_us: view} do
      assert experience(view, "Supply Midia").name == "Supply Midia"
    end

    test "derives the company logo from the display name", %{en_us: view} do
      assert experience(view, "Supply Midia").logo == "sq-supply-midia"
    end

    test "joins the location and the work mode", %{en_us: view} do
      assert experience(view, "Arionkoder").location ==
               "Massachusetts, United States · Remote"
    end

    test "shows an open role as ending at present", %{en_us: view} do
      assert experience(view, "R3M Tech").period == "Jun 2012 - Present"
    end

    test "translates the months", %{pt_br: view} do
      assert experience(view, "Arionkoder").period == "Out 2025 - Out 2026"
    end

    test "spans a company's period over all its roles", %{en_us: view} do
      assert experience(view, "Jaya Tech").period == "Feb 2018 - Jul 2022"
    end

    test "marks companies that ended up to 2012 as earlier", %{en_us: view} do
      assert experience(view, "Atos").earlier?
    end

    test "does not mark open companies as earlier", %{en_us: view} do
      refute experience(view, "R3M Tech").earlier?
    end

    test "keeps the text before the bullets as one paragraph", %{en_us: view} do
      assert ["As a software engineer at iSeatz" <> _rest] = role(view, "Arionkoder").paragraphs
    end

    test "separates the description bullets without the dash", %{en_us: view} do
      assert "Improved logs and error messages across the platform" in role(view, "Arionkoder").bullets
    end

    test "groups clients before projects, with labels", %{en_us: view} do
      assert Enum.map(role(view, "R3M Tech").references, & &1.label) == ["Clients", "Projects"]
    end

    test "derives the client logo from its name", %{en_us: view} do
      [_clients, projects] = role(view, "R3M Tech").references
      assert hd(projects.items).logo == "cl-iseatz-arionkoder"
    end

    test "joins degree and field of study", %{pt_br: view} do
      assert hd(view.educations).degree =~ "Pós-graduação, Ergonomia"
    end

    test "shows the display name of a school", %{en_us: view} do
      assert hd(view.educations).name == "PUC-Rio"
    end

    test "labels the skill groups", %{pt_br: view} do
      assert view.skills |> Enum.take(2) |> Enum.map(& &1.label) == [
               "IA",
               "Assistentes de código IA"
             ]
    end

    test "shows each language with its proficiency", %{en_us: view} do
      assert view.languages == [
               "English (professional)",
               "Portuguese (native)",
               "Spanish (elementary)"
             ]
    end

    test "anchors each company by name and start year", %{en_us: view} do
      assert view.experiences
             |> Enum.map(& &1.id)
             |> Enum.filter(&String.starts_with?(&1, "xp-brq")) ==
               ["xp-brq-2012", "xp-brq-2006"]
    end

    test "puts every company on the career bar", %{en_us: view} do
      assert Enum.map(view.timeline.companies, & &1.id) == Enum.map(view.experiences, & &1.id)
    end

    test "places a company by its dates on the career bar", %{en_us: view} do
      caixa = List.last(view.timeline.companies)
      assert {caixa.x, caixa.width} == {1.24, 1.24}
    end

    test "runs an open company to the end of the career bar", %{en_us: view} do
      r3m = hd(view.timeline.companies)
      assert Float.round(r3m.x + r3m.width, 1) == 100.0
    end

    test "puts only companies alongside others on the parallel lane", %{en_us: view} do
      assert for(company <- view.timeline.companies, company.parallel, do: company.name) == [
               "R3M Tech"
             ]
    end

    test "marks the decades and the end on the career bar", %{pt_br: view} do
      assert Enum.map(view.timeline.ticks, & &1.label) == ["2000", "2010", "2020", "hoje"]
    end

    test "leaves hidden recommendations out", %{en_us: view} do
      assert Enum.map(view.recommendations, & &1.name) == [
               "Farrell Dalsing",
               "Valeriia Maliarenko",
               "Gerson Scanapieco",
               "Leonardo Mello",
               "Vinci Amorim"
             ]
    end

    test "keeps the recommender's current headline", %{en_us: view} do
      assert hd(view.recommendations).headline ==
               "Senior Product Manager | Strategic Platform & Client Product Leadership | Hospitality & Travel Tech | Driving Scalable Booking & Revenue Experiences"
    end

    test "keeps the recommendation's highlight", %{en_us: view} do
      assert hd(view.recommendations).highlight =~
               "He elevates the quality of the work and the people around him"
    end

    test "knows a last-paragraph highlight leaves text out only before it", %{en_us: view} do
      assert hd(view.recommendations).omitted == %{before: true, after: false}
    end

    test "knows a middle highlight leaves text out on both sides", %{en_us: view} do
      gerson = Enum.find(view.recommendations, &(&1.name == "Gerson Scanapieco"))
      assert gerson.omitted == %{before: true, after: true}
    end

    test "knows a first-sentence highlight leaves text out only after it", %{en_us: view} do
      assert List.last(view.recommendations).omitted == %{before: false, after: true}
    end

    test "splits a recommendation into paragraphs", %{en_us: view} do
      assert length(hd(view.recommendations).paragraphs) == 7
    end

    test "joins relationship, workplace and date", %{en_us: view} do
      assert hd(view.recommendations).context == "Same team · iSeatz · Nov 2026"
    end

    test "shows the recommender's initials", %{en_us: view} do
      assert hd(view.recommendations).initials == "FD"
    end

    test "points to the recommender's photo", %{en_us: view} do
      assert hd(view.recommendations).photo == "/assets/images/people/farrell-dalsing.jpg"
    end

    test "translates the recommendation labels", %{pt_br: view} do
      assert hd(view.recommendations).context == "Mesmo time · iSeatz · Nov 2026"
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
