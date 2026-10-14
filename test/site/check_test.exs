defmodule Site.CheckTest do
  use ExUnit.Case, async: true

  alias Site.Check

  @moduletag :tmp_dir

  describe "run/1" do
    test "finds nothing broken in the published site" do
      assert Check.run("docs") == []
    end

    test "reports a missing file in an HTML attribute", %{tmp_dir: root} do
      write(root, "index.html", ~s(<img src="/missing.png">))
      assert Check.run(root) == [{"index.html", "/missing.png"}]
    end

    test "resolves a folder to its index.html", %{tmp_dir: root} do
      write(root, "resume/index.html", "")
      write(root, "index.html", ~s(<a href="/resume/">))
      assert Check.run(root) == []
    end

    test "resolves a relative reference from the file's folder", %{tmp_dir: root} do
      write(root, "pt/index.html", ~s(<a href="other.html">))
      assert Check.run(root) == [{"pt/index.html", "other.html"}]
    end

    test "ignores external links", %{tmp_dir: root} do
      write(root, "index.html", ~s(<a href="https://github.com/x"> <a href="mailto:a@b.c">))
      assert Check.run(root) == []
    end

    test "ignores content attributes that are not paths", %{tmp_dir: root} do
      write(root, "index.html", ~s(<meta name="author" content="raulpe7eira" />))
      assert Check.run(root) == []
    end

    test "checks site URLs in content attributes", %{tmp_dir: root} do
      write(root, "index.html", ~s(<meta content="https://raulpe7eira.tech/og.jpg" />))
      assert Check.run(root) == [{"index.html", "https://raulpe7eira.tech/og.jpg"}]
    end

    test "reports a missing sprite icon", %{tmp_dir: root} do
      write(root, "icons.svg", ~s(<symbol id="info"></symbol>))
      write(root, "index.html", ~s(<use href="/icons.svg#download"/>))
      assert Check.run(root) == [{"index.html", "/icons.svg#download"}]
    end

    test "reports a missing file in a CSS url()", %{tmp_dir: root} do
      write(root, "base.css", "body{background:url('/cover.jpg')}")
      assert Check.run(root) == [{"base.css", "/cover.jpg"}]
    end

    test "reports a missing page in the sitemap", %{tmp_dir: root} do
      write(root, "sitemap.xml", "<loc>https://raulpe7eira.tech/pt/</loc>")
      assert Check.run(root) == [{"sitemap.xml", "https://raulpe7eira.tech/pt/"}]
    end

    test "reports a missing path in JSON", %{tmp_dir: root} do
      write(root, "manifest.json", ~s({"icons": [{"src": "/icon.png"}]}))
      assert Check.run(root) == [{"manifest.json", "/icon.png"}]
    end
  end

  defp write(root, file, content) do
    path = Path.join(root, file)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end
end
