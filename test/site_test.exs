defmodule SiteTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @files [
    "index.html",
    "resume/index.html",
    "pt/index.html",
    "pt/resume/index.html",
    "llms.txt",
    "404.html",
    "sitemap.xml"
  ]

  @first ~D[2026-01-01]
  @second ~D[2026-02-01]

  describe "build/2" do
    test "returns the path of every file written", %{tmp_dir: dir} do
      assert Enum.sort(Site.build(dir)) == Enum.sort(Enum.map(@files, &Path.join(dir, &1)))
    end

    test "writes the files to disk", %{tmp_dir: dir} do
      assert dir |> Site.build() |> Enum.all?(&File.exists?/1)
    end

    test "prints no PDF unless asked", %{tmp_dir: dir} do
      Site.build(dir, pdf: false)

      refute File.exists?(Path.join(dir, "downloads/raul-pereira-da-silva-resume-en-us.pdf"))
    end

    test "dates new pages with today in the sitemap", %{tmp_dir: dir} do
      Site.build(dir, today: @first)

      assert lastmod(dir, "https://raulpe7eira.tech/resume/") == "2026-01-01"
    end

    test "keeps the date of a page that did not change", %{tmp_dir: dir} do
      Site.build(dir, today: @first)
      Site.build(dir, today: @second)

      assert lastmod(dir, "https://raulpe7eira.tech/resume/") == "2026-01-01"
    end

    test "dates a page that changed with today", %{tmp_dir: dir} do
      Site.build(dir, today: @first)
      File.write!(Path.join(dir, "resume/index.html"), "outdated")
      Site.build(dir, today: @second)

      assert lastmod(dir, "https://raulpe7eira.tech/resume/") == "2026-02-01"
    end

    test "keeps the date of the other pages when one changed", %{tmp_dir: dir} do
      Site.build(dir, today: @first)
      File.write!(Path.join(dir, "resume/index.html"), "outdated")
      Site.build(dir, today: @second)

      assert lastmod(dir, "https://raulpe7eira.tech/") == "2026-01-01"
    end
  end

  defp lastmod(dir, url) do
    xml = File.read!(Path.join(dir, "sitemap.xml"))
    [_, date] = Regex.run(~r{<loc>#{Regex.escape(url)}</loc>.*?<lastmod>([^<]+)</lastmod>}s, xml)
    date
  end
end
