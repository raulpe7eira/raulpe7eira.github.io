defmodule Site.LiveReload.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias Site.LiveReload.Plug, as: LiveReload

  @moduletag :tmp_dir

  setup %{tmp_dir: root} do
    File.mkdir_p!(Path.join(root, "resume"))
    File.write!(Path.join(root, "index.html"), "<body>home</body>")
    File.write!(Path.join(root, "resume/index.html"), "<body>resume</body>")
    File.write!(Path.join(root, "page.html"), "<body>page</body>")
    File.write!(Path.join(root, "404.html"), "not found")
    File.write!(Path.join(root, "style.css"), "body{}")
    %{opts: LiveReload.init(root: root, version: fn -> "7" end)}
  end

  describe "call/2" do
    test "answers the build version at /__live_reload", %{opts: opts} do
      assert request("/__live_reload", opts).resp_body == "7"
    end

    test "adds the reload script to a folder's index.html", %{opts: opts} do
      assert request("/resume/", opts).resp_body =~ "/__live_reload"
    end

    test "adds the reload script to an .html file", %{opts: opts} do
      assert request("/page.html", opts).resp_body =~ "/__live_reload"
    end

    test "serves other files as they are", %{opts: opts} do
      assert request("/style.css", opts).resp_body == "body{}"
    end

    test "keeps the redirect of a folder without the trailing slash", %{opts: opts} do
      assert request("/resume", opts).status == 301
    end
  end

  describe "inject/1" do
    test "puts the script before </body>" do
      assert LiveReload.inject("<body>home</body>") =~ ~r{</script>\s*</body>$}
    end

    test "appends the script when there is no </body>" do
      assert LiveReload.inject("home") =~ ~r{^home<script>}
    end
  end

  defp request(path, opts), do: :get |> conn(path) |> LiveReload.call(opts)
end
