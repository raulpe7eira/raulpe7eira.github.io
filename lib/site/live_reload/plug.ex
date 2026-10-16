defmodule Site.LiveReload.Plug do
  @moduledoc """
  Serves `docs/` like `Site.Server`, plus what reloads the browser while
  `mix site.server` watches the sources:

    * HTML pages get a small script before `</body>` that asks
      `/__live_reload` for the build version every second and reloads the
      page when it changes
    * `/__live_reload` answers the current version (see
      `Site.LiveReload.Watcher`)

  The script is added to the response only, never to the files in `docs/`.
  """

  @behaviour Plug

  import Plug.Conn

  @path "/__live_reload"
  @script """
  <script>(function(){var v;setInterval(function(){fetch("#{@path}",{cache:"no-store"}).then(function(r){return r.text()}).then(function(n){if(v&&n!==v)location.reload();v=n}).catch(function(){})},1000)})()</script>
  """

  @impl Plug
  def init(opts) do
    root = Keyword.get(opts, :root, "docs")
    %{root: root, version: Keyword.fetch!(opts, :version), server: Site.Server.init(root: root)}
  end

  @impl Plug
  def call(%{request_path: @path} = conn, %{version: version}) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(200, version.())
    |> halt()
  end

  def call(conn, %{root: root, server: server}) do
    case html_file(root, conn) do
      nil ->
        Site.Server.call(conn, server)

      file ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, file |> File.read!() |> inject())
        |> halt()
    end
  end

  @doc "Adds the reload script before `</body>`, or at the end when there is none."
  def inject(html) do
    if String.contains?(html, "</body>"),
      do: String.replace(html, "</body>", @script <> "</body>", global: false),
      else: html <> @script
  end

  # the HTML file a request gets (a folder's index.html or an .html file), or nil
  defp html_file(root, conn) do
    path = Path.join([root | conn.path_info])
    index = Path.join(path, "index.html")

    cond do
      ".." in conn.path_info -> nil
      String.ends_with?(conn.request_path, "/") and File.regular?(index) -> index
      String.ends_with?(path, ".html") and File.regular?(path) -> path
      true -> nil
    end
  end
end
