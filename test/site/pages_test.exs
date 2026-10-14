defmodule Site.PagesTest do
  use ExUnit.Case, async: true

  alias Site.Pages
  alias Site.Resume

  setup_all do
    %{resume: Resume.load!()}
  end

  describe "home/1" do
    test "writes the English page to index.html" do
      assert {"index.html", _html} = Pages.home(:en_us)
    end

    test "writes the Portuguese page to pt/index.html" do
      assert {"pt/index.html", _html} = Pages.home(:pt_br)
    end

    test "sets lang=en-US on the English page" do
      assert home(:en_us) =~ ~s(<html lang="en-US">)
    end

    test "sets lang=pt-BR on the Portuguese page" do
      assert home(:pt_br) =~ ~s(<html lang="pt-BR">)
    end

    test "has the English title" do
      assert home(:en_us) =~ "<title>Raul Pereira (raulpe7eira) - Software Engineer</title>"
    end

    test "has the Portuguese title" do
      assert home(:pt_br) =~ "<title>Raul Pereira (raulpe7eira) - Engenheiro de Software</title>"
    end

    test "has the English description" do
      assert home(:en_us) =~
               ~s(<meta name="description" content="Software engineer with 20+ years)
    end

    test "has the Portuguese description" do
      assert home(:pt_br) =~ ~s(<meta name="description" content="Engenheiro de software)
    end

    test "English canonical points to itself" do
      assert home(:en_us) =~ ~s(<link rel="canonical" href="https://raulpe7eira.tech/" />)
    end

    test "Portuguese canonical points to itself" do
      assert home(:pt_br) =~ ~s(<link rel="canonical" href="https://raulpe7eira.tech/pt/" />)
    end

    test "hreflang en-US points to the English page" do
      assert home(:pt_br) =~ ~s(hreflang="en-US" href="https://raulpe7eira.tech/")
    end

    test "hreflang pt-BR points to the Portuguese page" do
      assert home(:en_us) =~ ~s(hreflang="pt-BR" href="https://raulpe7eira.tech/pt/")
    end

    test "hreflang x-default points to the English page" do
      assert home(:pt_br) =~ ~s(hreflang="x-default" href="https://raulpe7eira.tech/")
    end

    test "English language switch links to the Portuguese page" do
      assert home(:en_us) =~ ~s(<a class="lang-btn" href="/pt/" hreflang="pt-BR")
    end

    test "Portuguese language switch links to the English page" do
      assert home(:pt_br) =~ ~s(<a class="lang-btn" href="/" hreflang="en-US")
    end

    test "English resume switch is off and links to /resume/" do
      assert home(:en_us) =~
               ~s(<a class="page-btn" href="/resume/" role="switch" aria-checked="false">)
    end

    test "Portuguese resume switch is off and links to /pt/resume/" do
      assert home(:pt_br) =~
               ~s(<a class="page-btn" href="/pt/resume/" role="switch" aria-checked="false">)
    end

    test "English JSON-LD is a valid Person with the English job title" do
      assert %{"@type" => "Person", "jobTitle" => "Software Engineer"} = jsonld(home(:en_us))
    end

    test "Portuguese JSON-LD is a valid Person with the Portuguese job title" do
      assert %{"@type" => "Person", "jobTitle" => "Engenheiro de Software"} = jsonld(home(:pt_br))
    end

    test "English page uses only icons defined in the sprite" do
      assert icon_refs(home(:en_us)) -- sprite_ids() == []
    end

    test "Portuguese page uses only icons defined in the sprite" do
      assert icon_refs(home(:pt_br)) -- sprite_ids() == []
    end

    test "leaves no template tags in the English page" do
      refute home(:en_us) =~ "<%"
    end

    test "leaves no template tags in the Portuguese page" do
      refute home(:pt_br) =~ "<%"
    end
  end

  describe "resume/2" do
    test "writes the English resume to resume/index.html", %{resume: resume} do
      assert {"resume/index.html", _html} = Pages.resume(:en_us, resume)
    end

    test "writes the Portuguese resume to pt/resume/index.html", %{resume: resume} do
      assert {"pt/resume/index.html", _html} = Pages.resume(:pt_br, resume)
    end

    test "has the English title", %{resume: resume} do
      assert resume(:en_us, resume) =~ "<title>Raul Pereira (raulpe7eira) - Resume</title>"
    end

    test "has the Portuguese title", %{resume: resume} do
      assert resume(:pt_br, resume) =~ "<title>Raul Pereira (raulpe7eira) - Currículo</title>"
    end

    test "English canonical points to itself", %{resume: resume} do
      assert resume(:en_us, resume) =~
               ~s(<link rel="canonical" href="https://raulpe7eira.tech/resume/" />)
    end

    test "Portuguese canonical points to itself", %{resume: resume} do
      assert resume(:pt_br, resume) =~
               ~s(<link rel="canonical" href="https://raulpe7eira.tech/pt/resume/" />)
    end

    test "English language switch links to the Portuguese resume", %{resume: resume} do
      assert resume(:en_us, resume) =~ ~s(<a class="lang-btn" href="/pt/resume/" hreflang="pt-BR")
    end

    test "English resume switch is on and links back home", %{resume: resume} do
      assert resume(:en_us, resume) =~
               ~s(<a class="page-btn on" href="/" role="switch" aria-checked="true" aria-current="page">)
    end

    test "Portuguese resume switch is on and links back home", %{resume: resume} do
      assert resume(:pt_br, resume) =~
               ~s(<a class="page-btn on" href="/pt/" role="switch" aria-checked="true" aria-current="page">)
    end

    test "loads no fonts from Google", %{resume: resume} do
      refute resume(:en_us, resume) =~ "fonts.googleapis.com"
    end

    test "preloads the self-hosted font", %{resume: resume} do
      assert resume(:en_us, resume) =~
               ~s(<link rel="preload" href="/assets/fonts/inter-regular.woff2")
    end

    test "loads the resume styles", %{resume: resume} do
      assert resume(:en_us, resume) =~ ~s(<link rel="stylesheet" href="/assets/css/resume.css" />)
    end

    test "English JSON-LD is a ProfilePage in English", %{resume: resume} do
      assert %{"@type" => "ProfilePage", "inLanguage" => "en-US"} = jsonld(resume(:en_us, resume))
    end

    test "Portuguese JSON-LD is a ProfilePage in Portuguese", %{resume: resume} do
      assert %{"@type" => "ProfilePage", "inLanguage" => "pt-BR"} = jsonld(resume(:pt_br, resume))
    end

    test "English page links the English PDF", %{resume: resume} do
      assert resume(:en_us, resume) =~
               ~s(href="/downloads/raul-pereira-da-silva-resume-en-us.pdf" download="raul-pereira-da-silva-resume.pdf")
    end

    test "Portuguese page links the Portuguese PDF", %{resume: resume} do
      assert resume(:pt_br, resume) =~
               ~s(href="/downloads/raul-pereira-da-silva-resume-pt-br.pdf" download="raul-pereira-da-silva-curriculo.pdf")
    end

    test "has the English section titles", %{resume: resume} do
      assert resume(:en_us, resume) =~ "<h2>Experience</h2>"
    end

    test "has the Portuguese section titles", %{resume: resume} do
      assert resume(:pt_br, resume) =~ "<h2>Experiência</h2>"
    end

    test "escapes text from the data", %{resume: resume} do
      assert resume(:en_us, resume) =~ "Amex&#x27;s travel platform"
    end

    test "marks companies that were acquired", %{resume: resume} do
      assert resume(:en_us, resume) =~
               ~s(<span class="acq" title="acquired by Evertec">acquired</span>)
    end

    test "marks schools that closed", %{resume: resume} do
      assert resume(:pt_br, resume) =~ ~s(title="Encerrado em 2014")
    end

    test "leaves no whitespace between the stack chips", %{resume: resume} do
      assert resume(:en_us, resume) =~ "<span>Elixir</span><span>Phoenix</span>"
    end

    test "uses only logos that exist", %{resume: resume} do
      logos =
        ~r{src="/assets/images/logos/([\w-]+\.png)"}
        |> Regex.scan(resume(:en_us, resume), capture: :all_but_first)
        |> List.flatten()

      assert Enum.reject(logos, &File.exists?(Path.join("docs/assets/images/logos", &1))) == []
    end

    test "English page uses only icons defined in the sprite", %{resume: resume} do
      assert icon_refs(resume(:en_us, resume)) -- sprite_ids() == []
    end

    test "Portuguese page uses only icons defined in the sprite", %{resume: resume} do
      assert icon_refs(resume(:pt_br, resume)) -- sprite_ids() == []
    end

    test "leaves no template tags in the English page", %{resume: resume} do
      refute resume(:en_us, resume) =~ "<%"
    end

    test "leaves no template tags in the Portuguese page", %{resume: resume} do
      refute resume(:pt_br, resume) =~ "<%"
    end
  end

  describe "resume_pdf/3" do
    test "names the English PDF", %{resume: resume} do
      assert {"downloads/raul-pereira-da-silva-resume-en-us.pdf", _html} =
               Pages.resume_pdf(:en_us, resume, "/fonts")
    end

    test "names the Portuguese PDF", %{resume: resume} do
      assert {"downloads/raul-pereira-da-silva-resume-pt-br.pdf", _html} =
               Pages.resume_pdf(:pt_br, resume, "/fonts")
    end

    test "sets the English document title", %{resume: resume} do
      assert pdf(:en_us, resume) =~ "<title>Raul Pereira da Silva - Resume</title>"
    end

    test "sets the Portuguese document title", %{resume: resume} do
      assert pdf(:pt_br, resume) =~ "<title>Raul Pereira da Silva - Currículo</title>"
    end

    test "loads the fonts from fonts_dir", %{resume: resume} do
      assert pdf(:en_us, resume) =~ ~s{url("/fonts/inter-regular.woff2")}
    end

    test "condenses roles that ended up to 2012 under earlier experience", %{resume: resume} do
      assert pdf(:en_us, resume) =~
               ~s(<b><a href="https://atos.net">Atos</a></b><span>Senior System Analyst · )
    end

    test "keeps the full entry of roles that ended after 2012", %{resume: resume} do
      assert pdf(:en_us, resume) =~
               ~s(<div class="jh"><span><a href="https://www.brq.com">BRQ</a>)
    end

    test "joins references and stack on one line", %{resume: resume} do
      assert pdf(:en_us, resume) =~ "<i>Projects:</i> iSeatz &nbsp;·&nbsp; <i>Stack:</i> Elixir"
    end

    test "joins clients and projects on one line", %{resume: resume} do
      assert pdf(:en_us, resume) =~ "Bioxxi &nbsp;·&nbsp; <i>Projects:</i> ARCA (Fiocruz)"
    end

    test "leaves no template tags", %{resume: resume} do
      refute pdf(:en_us, resume) =~ "<%"
    end
  end

  describe "all/1" do
    test "renders every page and text file, loading the resume data by default" do
      assert Enum.map(Pages.all(), &elem(&1, 0)) == [
               "index.html",
               "resume/index.html",
               "pt/index.html",
               "pt/resume/index.html",
               "llms.txt",
               "404.html"
             ]
    end

    test "renders every file from the given resume", %{resume: resume} do
      assert length(Pages.all(resume)) == 6
    end
  end

  describe "sitemap_pages/0" do
    test "lists each page with its URL, homes first" do
      assert Pages.sitemap_pages() == [
               {"index.html", "https://raulpe7eira.tech/"},
               {"pt/index.html", "https://raulpe7eira.tech/pt/"},
               {"resume/index.html", "https://raulpe7eira.tech/resume/"},
               {"pt/resume/index.html", "https://raulpe7eira.tech/pt/resume/"}
             ]
    end
  end

  describe "sitemap/1" do
    test "writes to sitemap.xml" do
      assert {"sitemap.xml", _xml} = Pages.sitemap(lastmods())
    end

    test "lists every page" do
      assert length(Regex.scan(~r{<loc>}, sitemap())) == 4
    end

    test "dates each page with its lastmod" do
      assert sitemap() =~
               ~r{<loc>https://raulpe7eira.tech/pt/resume/</loc>.*?<lastmod>2026-01-04</lastmod>}s
    end

    test "links the Portuguese alternate of each page" do
      assert sitemap() =~
               ~s(<xhtml:link rel="alternate" hreflang="pt-BR" href="https://raulpe7eira.tech/pt/resume/" />)
    end

    test "points x-default to the English page" do
      assert sitemap() =~
               ~s(<xhtml:link rel="alternate" hreflang="x-default" href="https://raulpe7eira.tech/resume/" />)
    end

    test "has no changefreq or priority" do
      refute sitemap() =~ ~r/changefreq|priority/
    end
  end

  describe "llms/1" do
    test "writes to llms.txt", %{resume: resume} do
      assert {"llms.txt", _text} = Pages.llms(resume)
    end

    test "links the Portuguese PDF", %{resume: resume} do
      assert llms(resume) =~
               "- Resume PDF (PT): https://raulpe7eira.tech/downloads/raul-pereira-da-silva-resume-pt-br.pdf"
    end

    test "takes the career highlights from the data", %{resume: resume} do
      assert llms(resume) =~ "Career highlights: " <> resume.highlights.en_us
    end
  end

  describe "not_found/0" do
    test "writes to 404.html" do
      assert {"404.html", _html} = Pages.not_found()
    end

    test "sends unknown Portuguese addresses to the Portuguese home" do
      assert not_found() =~ ~s(var homes = ["/pt/"];)
    end

    test "is in the default locale" do
      assert not_found() =~ ~s(<html lang="en-US">)
    end
  end

  defp home(lang), do: lang |> Pages.home() |> elem(1)
  defp sitemap, do: lastmods() |> Pages.sitemap() |> elem(1)
  defp llms(resume), do: resume |> Pages.llms() |> elem(1)
  defp not_found, do: elem(Pages.not_found(), 1)

  defp lastmods do
    Pages.sitemap_pages()
    |> Enum.with_index(1)
    |> Map.new(fn {{_file, url}, day} -> {url, Date.new!(2026, 1, day)} end)
  end

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
