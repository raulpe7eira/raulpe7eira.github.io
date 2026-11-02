defmodule Site.Screenshots.Plug do
  @moduledoc """
  Serves `docs/` like `Site.Server`, plus `/__screenshot`, the page
  `Site.Screenshots` captures: the home page in an iframe of the screen size
  given by the `width` and `height` query parameters.

  Served from the same origin as the site, the frame stores a cookie choice
  in `localStorage` (the key `docs/assets/js/analytics.js` reads) before the
  iframe loads, so the consent banner stays hidden in the screenshots.
  """

  @behaviour Plug

  import Plug.Conn

  @path "/__screenshot"

  @impl Plug
  def init(opts), do: %{server: Site.Server.init(root: Keyword.get(opts, :root, "docs"))}

  @impl Plug
  def call(%{request_path: @path} = conn, _opts) do
    %{"width" => width, "height" => height} = fetch_query_params(conn).query_params

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, frame(String.to_integer(width), String.to_integer(height)))
    |> halt()
  end

  def call(conn, %{server: server}), do: Site.Server.call(conn, server)

  @doc "Path of the frame for a `width`×`height` screen."
  def path(width, height), do: "#{@path}?width=#{width}&height=#{height}"

  @doc "The frame: stores the cookie choice, then loads the home page in a `width`×`height` iframe."
  def frame(width, height) do
    """
    <html><body style="margin:0">
    <script>try{localStorage.setItem("analytics-consent","denied")}catch(e){}</script>
    <iframe src="/" width="#{width}" height="#{height}" scrolling="no" style="border:0;display:block"></iframe>
    </body></html>
    """
  end
end
