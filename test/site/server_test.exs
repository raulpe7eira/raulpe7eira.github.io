defmodule Site.ServerTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias Site.Server

  @moduletag :tmp_dir

  setup %{tmp_dir: root} do
    File.mkdir_p!(Path.join(root, "resume"))
    File.write!(Path.join(root, "index.html"), "home")
    File.write!(Path.join(root, "resume/index.html"), "resume")
    File.write!(Path.join(root, "404.html"), "not found")
    File.write!(Path.join(root, "style.css"), "body{}")
    %{opts: Server.init(root: root)}
  end

  describe "call/2" do
    test "serves the home page at /", %{opts: opts} do
      assert request("/", opts).resp_body == "home"
    end

    test "serves a folder's index.html", %{opts: opts} do
      assert request("/resume/", opts).resp_body == "resume"
    end

    test "redirects a folder without the trailing slash", %{opts: opts} do
      assert request("/resume", opts).status == 301
    end

    test "redirects to the folder with the trailing slash", %{opts: opts} do
      assert Plug.Conn.get_resp_header(request("/resume", opts), "location") == ["/resume/"]
    end

    test "serves a file", %{opts: opts} do
      assert request("/style.css", opts).resp_body == "body{}"
    end

    test "answers an unknown address with 404.html", %{opts: opts} do
      assert request("/nope", opts).resp_body == "not found"
    end

    test "answers an unknown address with status 404", %{opts: opts} do
      assert request("/nope", opts).status == 404
    end
  end

  defp request(path, opts), do: :get |> conn(path) |> Server.call(opts)
end
