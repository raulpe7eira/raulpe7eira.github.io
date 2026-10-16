defmodule Site.Server do
  @moduledoc """
  Serves `docs/` locally the way GitHub Pages does: a folder serves its
  `index.html` (and `/resume` redirects to `/resume/`), and an unknown
  address gets `404.html` with status 404.

  Used by `mix site.server`; Bandit and Plug are dev/test dependencies only.
  """

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts) do
    root = Keyword.get(opts, :root, "docs")
    %{root: root, static: Plug.Static.init(at: "/", from: root)}
  end

  @impl Plug
  def call(conn, %{root: root, static: static}) do
    if File.dir?(Path.join([root | conn.path_info])) do
      serve_folder(conn, static)
    else
      serve_file(conn, root, static)
    end
  end

  defp serve_folder(conn, static) do
    if String.ends_with?(conn.request_path, "/") do
      Plug.Static.call(%{conn | path_info: conn.path_info ++ ["index.html"]}, static)
    else
      conn
      |> put_resp_header("location", conn.request_path <> "/")
      |> send_resp(301, "")
      |> halt()
    end
  end

  defp serve_file(conn, root, static) do
    conn = Plug.Static.call(conn, static)

    if conn.halted do
      conn
    else
      conn
      |> put_resp_content_type("text/html")
      |> send_file(404, Path.join(root, "404.html"))
      |> halt()
    end
  end
end
