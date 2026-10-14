defmodule Site.PagesTest do
  use ExUnit.Case, async: true

  alias Site.Pages

  describe "home/1" do
    test "writes the English page to index.html" do
      assert {"index.html", _html} = Pages.home(:en)
    end

    test "writes the Portuguese page to pt/index.html" do
      assert {"pt/index.html", _html} = Pages.home(:pt)
    end

    test "sets lang=en on the English page" do
      assert html(:en) =~ ~s(<html lang="en">)
    end

    test "sets lang=pt-BR on the Portuguese page" do
      assert html(:pt) =~ ~s(<html lang="pt-BR">)
    end

    test "has the English title" do
      assert html(:en) =~ "<title>Raul Pereira (raulpe7eira) - Software Engineer</title>"
    end

    test "has the Portuguese title" do
      assert html(:pt) =~ "<title>Raul Pereira (raulpe7eira) - Engenheiro de Software</title>"
    end

    test "has the English description" do
      assert html(:en) =~ ~s(<meta name="description" content="Software engineer with 20+ years)
    end

    test "has the Portuguese description" do
      assert html(:pt) =~ ~s(<meta name="description" content="Engenheiro de software)
    end

    test "English canonical points to itself" do
      assert html(:en) =~ ~s(<link rel="canonical" href="https://raulpe7eira.tech/" />)
    end

    test "Portuguese canonical points to itself" do
      assert html(:pt) =~ ~s(<link rel="canonical" href="https://raulpe7eira.tech/pt/" />)
    end

    test "hreflang en points to the English page" do
      assert html(:pt) =~ ~s(hreflang="en" href="https://raulpe7eira.tech/")
    end

    test "hreflang pt-BR points to the Portuguese page" do
      assert html(:en) =~ ~s(hreflang="pt-BR" href="https://raulpe7eira.tech/pt/")
    end

    test "hreflang x-default points to the English page" do
      assert html(:pt) =~ ~s(hreflang="x-default" href="https://raulpe7eira.tech/")
    end

    test "English language switch links to the Portuguese page" do
      assert html(:en) =~ ~s(<a class="lang-btn" href="/pt/" hreflang="pt-BR")
    end

    test "Portuguese language switch links to the English page" do
      assert html(:pt) =~ ~s(<a class="lang-btn" href="/" hreflang="en")
    end

    test "English resume switch is off and links to /resume/" do
      assert html(:en) =~
               ~s(<a class="page-btn" href="/resume/" role="switch" aria-checked="false">)
    end

    test "Portuguese resume switch is off and links to /pt/resume/" do
      assert html(:pt) =~
               ~s(<a class="page-btn" href="/pt/resume/" role="switch" aria-checked="false">)
    end

    test "English JSON-LD is a valid Person with the English job title" do
      assert %{"@type" => "Person", "jobTitle" => "Software Engineer"} = jsonld(:en)
    end

    test "Portuguese JSON-LD is a valid Person with the Portuguese job title" do
      assert %{"@type" => "Person", "jobTitle" => "Engenheiro de Software"} = jsonld(:pt)
    end

    test "English page uses only icons defined in the sprite" do
      assert icon_refs(:en) -- sprite_ids() == []
    end

    test "Portuguese page uses only icons defined in the sprite" do
      assert icon_refs(:pt) -- sprite_ids() == []
    end

    test "leaves no template tags in the English page" do
      refute html(:en) =~ "<%"
    end

    test "leaves no template tags in the Portuguese page" do
      refute html(:pt) =~ "<%"
    end
  end

  describe "all/0" do
    test "renders every page" do
      assert Enum.map(Pages.all(), &elem(&1, 0)) == ["index.html", "pt/index.html"]
    end
  end

  defp html(lang), do: lang |> Pages.home() |> elem(1)

  defp icon_refs(lang) do
    ~r{<use href="/assets/icons\.svg#([\w-]+)"/>}
    |> Regex.scan(html(lang), capture: :all_but_first)
    |> List.flatten()
  end

  defp sprite_ids do
    ~r{<symbol id="([\w-]+)"}
    |> Regex.scan(File.read!("docs/assets/icons.svg"), capture: :all_but_first)
    |> List.flatten()
  end

  defp jsonld(lang) do
    [_, json] = Regex.run(~r{<script type="application/ld\+json">(.*?)</script>}s, html(lang))
    JSON.decode!(json)
  end
end
