defmodule Site.Screenshots.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias Site.Screenshots.Plug, as: FramePlug

  @moduletag :tmp_dir

  setup %{tmp_dir: root} do
    File.write!(Path.join(root, "index.html"), "<body>home</body>")
    File.write!(Path.join(root, "404.html"), "not found")
    %{opts: FramePlug.init(root: root)}
  end

  describe "call/2" do
    test "serves the frame at /__screenshot", %{opts: opts} do
      assert request("/__screenshot?width=412&height=915", opts).resp_body ==
               FramePlug.frame(412, 915)
    end

    test "serves the frame as HTML", %{opts: opts} do
      assert {"content-type", "text/html; charset=utf-8"} in
               request("/__screenshot?width=412&height=915", opts).resp_headers
    end

    test "serves the site's files like Site.Server", %{opts: opts} do
      assert request("/", opts).resp_body == "<body>home</body>"
    end
  end

  describe "path/2" do
    test "passes the screen size as query parameters" do
      assert FramePlug.path(1280, 800) == "/__screenshot?width=1280&height=800"
    end
  end

  describe "frame/2" do
    test "declines the cookies before the iframe loads" do
      assert FramePlug.frame(412, 915) =~
               ~r{localStorage\.setItem\("analytics-consent","denied"\).*<iframe}s
    end

    test "loads the home page in an iframe of the screen size" do
      assert FramePlug.frame(412, 915) =~ ~s(<iframe src="/" width="412" height="915")
    end
  end

  defp request(path, opts), do: :get |> conn(path) |> FramePlug.call(opts)
end
