defmodule Site.PagesTest do
  use ExUnit.Case, async: true

  alias Site.Pages
  alias Site.Resume

  setup_all do
    %{resume: Resume.load!()}
  end

  describe "home/1" do
    test "writes the English page to index.html" do
      assert {"index.html", _html} = Pages.home(:en)
    end

    test "writes the Portuguese page to pt/index.html" do
      assert {"pt/index.html", _html} = Pages.home(:pt)
    end

    test "sets lang=en on the English page" do
      assert home(:en) =~ ~s(<html lang="en">)
    end

    test "sets lang=pt-BR on the Portuguese page" do
      assert home(:pt) =~ ~s(<html lang="pt-BR">)
    end

    test "has the English title" do
      assert home(:en) =~ "<title>Raul Pereira (raulpe7eira) - Software Engineer</title>"
    end

    test "has the Portuguese title" do
      assert home(:pt) =~ "<title>Raul Pereira (raulpe7eira) - Engenheiro de Software</title>"
    end

    test "has the English description" do
      assert home(:en) =~ ~s(<meta name="description" content="Software engineer with 20+ years)
    end

    test "has the Portuguese description" do
      assert home(:pt) =~ ~s(<meta name="description" content="Engenheiro de software)
    end

    test "English canonical points to itself" do
      assert home(:en) =~ ~s(<link rel="canonical" href="https://raulpe7eira.tech/" />)
    end

    test "Portuguese canonical points to itself" do
      assert home(:pt) =~ ~s(<link rel="canonical" href="https://raulpe7eira.tech/pt/" />)
    end

    test "hreflang en points to the English page" do
      assert home(:pt) =~ ~s(hreflang="en" href="https://raulpe7eira.tech/")
    end

    test "hreflang pt-BR points to the Portuguese page" do
      assert home(:en) =~ ~s(hreflang="pt-BR" href="https://raulpe7eira.tech/pt/")
    end

    test "hreflang x-default points to the English page" do
      assert home(:pt) =~ ~s(hreflang="x-default" href="https://raulpe7eira.tech/")
    end

    test "English language switch links to the Portuguese page" do
      assert home(:en) =~ ~s(<a class="lang-btn" href="/pt/" hreflang="pt-BR")
    end

    test "Portuguese language switch links to the English page" do
      assert home(:pt) =~ ~s(<a class="lang-btn" href="/" hreflang="en")
    end

    test "English resume switch is off and links to /resume/" do
      assert home(:en) =~
               ~s(<a class="page-btn" href="/resume/" role="switch" aria-checked="false">)
    end

    test "Portuguese resume switch is off and links to /pt/resume/" do
      assert home(:pt) =~
               ~s(<a class="page-btn" href="/pt/resume/" role="switch" aria-checked="false">)
    end

    test "English JSON-LD is a valid Person with the English job title" do
      assert %{"@type" => "Person", "jobTitle" => "Software Engineer"} = jsonld(home(:en))
    end

    test "Portuguese JSON-LD is a valid Person with the Portuguese job title" do
      assert %{"@type" => "Person", "jobTitle" => "Engenheiro de Software"} = jsonld(home(:pt))
    end

    test "English page uses only icons defined in the sprite" do
      assert icon_refs(home(:en)) -- sprite_ids() == []
    end

    test "Portuguese page uses only icons defined in the sprite" do
      assert icon_refs(home(:pt)) -- sprite_ids() == []
    end

    test "leaves no template tags in the English page" do
      refute home(:en) =~ "<%"
    end

    test "leaves no template tags in the Portuguese page" do
      refute home(:pt) =~ "<%"
    end
  end

  describe "resume/2" do
    test "writes the English resume to resume/index.html", %{resume: resume} do
      assert {"resume/index.html", _html} = Pages.resume(:en, resume)
    end

    test "writes the Portuguese resume to pt/resume/index.html", %{resume: resume} do
      assert {"pt/resume/index.html", _html} = Pages.resume(:pt, resume)
    end

    test "has the English title", %{resume: resume} do
      assert resume(:en, resume) =~ "<title>Raul Pereira (raulpe7eira) - Resume</title>"
    end

    test "has the Portuguese title", %{resume: resume} do
      assert resume(:pt, resume) =~ "<title>Raul Pereira (raulpe7eira) - Currículo</title>"
    end

    test "English canonical points to itself", %{resume: resume} do
      assert resume(:en, resume) =~
               ~s(<link rel="canonical" href="https://raulpe7eira.tech/resume/" />)
    end

    test "Portuguese canonical points to itself", %{resume: resume} do
      assert resume(:pt, resume) =~
               ~s(<link rel="canonical" href="https://raulpe7eira.tech/pt/resume/" />)
    end

    test "English language switch links to the Portuguese resume", %{resume: resume} do
      assert resume(:en, resume) =~ ~s(<a class="lang-btn" href="/pt/resume/" hreflang="pt-BR")
    end

    test "English resume switch is on and links back home", %{resume: resume} do
      assert resume(:en, resume) =~
               ~s(<a class="page-btn on" href="/" role="switch" aria-checked="true" aria-current="page">)
    end

    test "Portuguese resume switch is on and links back home", %{resume: resume} do
      assert resume(:pt, resume) =~
               ~s(<a class="page-btn on" href="/pt/" role="switch" aria-checked="true" aria-current="page">)
    end

    test "loads the resume styles", %{resume: resume} do
      assert resume(:en, resume) =~ ~s(<link rel="stylesheet" href="/assets/css/resume.css" />)
    end

    test "English JSON-LD is a ProfilePage in English", %{resume: resume} do
      assert %{"@type" => "ProfilePage", "inLanguage" => "en"} = jsonld(resume(:en, resume))
    end

    test "Portuguese JSON-LD is a ProfilePage in Portuguese", %{resume: resume} do
      assert %{"@type" => "ProfilePage", "inLanguage" => "pt-BR"} = jsonld(resume(:pt, resume))
    end

    test "English page links the English PDF", %{resume: resume} do
      assert resume(:en, resume) =~ ~s(href="raul-pereira-da-silva-resume.pdf" download)
    end

    test "Portuguese page links the Portuguese PDF", %{resume: resume} do
      assert resume(:pt, resume) =~ ~s(href="raul-pereira-da-silva-curriculo.pdf" download)
    end

    test "has the English section titles", %{resume: resume} do
      assert resume(:en, resume) =~ "<h2>Experience</h2>"
    end

    test "has the Portuguese section titles", %{resume: resume} do
      assert resume(:pt, resume) =~ "<h2>Experiência</h2>"
    end

    test "escapes text from the data", %{resume: resume} do
      assert resume(:en, resume) =~ "Amex&#x27;s travel platform"
    end

    test "marks companies that were acquired", %{resume: resume} do
      assert resume(:en, resume) =~
               ~s(<span class="acq" title="acquired by Evertec">acquired</span>)
    end

    test "marks schools that closed", %{resume: resume} do
      assert resume(:pt, resume) =~ ~s(title="Encerrado em 2014")
    end

    test "leaves no whitespace between the stack chips", %{resume: resume} do
      assert resume(:en, resume) =~ "<span>Elixir</span><span>Phoenix</span>"
    end

    test "uses only logos that exist", %{resume: resume} do
      logos =
        ~r{src="/resume/lg/([\w-]+\.png)"}
        |> Regex.scan(resume(:en, resume), capture: :all_but_first)
        |> List.flatten()

      assert Enum.reject(logos, &File.exists?(Path.join("docs/resume/lg", &1))) == []
    end

    test "English page uses only icons defined in the sprite", %{resume: resume} do
      assert icon_refs(resume(:en, resume)) -- sprite_ids() == []
    end

    test "Portuguese page uses only icons defined in the sprite", %{resume: resume} do
      assert icon_refs(resume(:pt, resume)) -- sprite_ids() == []
    end

    test "leaves no template tags in the English page", %{resume: resume} do
      refute resume(:en, resume) =~ "<%"
    end

    test "leaves no template tags in the Portuguese page", %{resume: resume} do
      refute resume(:pt, resume) =~ "<%"
    end
  end

  describe "resume_pdf/3" do
    test "names the English PDF", %{resume: resume} do
      assert {"resume/raul-pereira-da-silva-resume.pdf", _html} =
               Pages.resume_pdf(:en, resume, "/fonts")
    end

    test "names the Portuguese PDF", %{resume: resume} do
      assert {"pt/resume/raul-pereira-da-silva-curriculo.pdf", _html} =
               Pages.resume_pdf(:pt, resume, "/fonts")
    end

    test "sets the English document title", %{resume: resume} do
      assert pdf(:en, resume) =~ "<title>Raul Pereira da Silva - Resume</title>"
    end

    test "sets the Portuguese document title", %{resume: resume} do
      assert pdf(:pt, resume) =~ "<title>Raul Pereira da Silva - Currículo</title>"
    end

    test "loads the fonts from fonts_dir", %{resume: resume} do
      assert pdf(:en, resume) =~ ~s{url("/fonts/Inter-Regular.ttf")}
    end

    test "condenses roles that ended up to 2012 under earlier experience", %{resume: resume} do
      assert pdf(:en, resume) =~
               ~s(<b><a href="https://atos.net">Atos</a></b><span>Senior System Analyst · )
    end

    test "keeps the full entry of roles that ended after 2012", %{resume: resume} do
      assert pdf(:en, resume) =~ ~s(<div class="jh"><span><a href="https://www.brq.com">BRQ</a>)
    end

    test "joins references and stack on one line", %{resume: resume} do
      assert pdf(:en, resume) =~ "<i>Projects:</i> iSeatz &nbsp;·&nbsp; <i>Stack:</i> Elixir"
    end

    test "joins clients and projects on one line", %{resume: resume} do
      assert pdf(:en, resume) =~ "Bioxxi &nbsp;·&nbsp; <i>Projects:</i> ARCA (Fiocruz)"
    end

    test "leaves no template tags", %{resume: resume} do
      refute pdf(:en, resume) =~ "<%"
    end
  end

  describe "all/1" do
    test "renders every page, loading the resume data by default" do
      assert Enum.map(Pages.all(), &elem(&1, 0)) ==
               ["index.html", "resume/index.html", "pt/index.html", "pt/resume/index.html"]
    end

    test "renders every page from the given resume", %{resume: resume} do
      assert length(Pages.all(resume)) == 4
    end
  end

  defp home(lang), do: lang |> Pages.home() |> elem(1)
  defp resume(lang, resume), do: lang |> Pages.resume(resume) |> elem(1)
  defp pdf(lang, resume), do: lang |> Pages.resume_pdf(resume, "/fonts") |> elem(1)

  defp icon_refs(html) do
    ~r{<use href="/assets/icons\.svg#([\w-]+)"/>}
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end

  defp sprite_ids do
    ~r{<symbol id="([\w-]+)"}
    |> Regex.scan(File.read!("docs/assets/icons.svg"), capture: :all_but_first)
    |> List.flatten()
  end

  defp jsonld(html) do
    [_, json] = Regex.run(~r{<script type="application/ld\+json">(.*?)</script>}s, html)
    JSON.decode!(json)
  end
end
