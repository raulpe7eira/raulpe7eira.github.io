defmodule Site.Screenshots do
  @moduledoc """
  Captures the screenshots of the home page listed in the web manifest, which
  Android and desktop Chrome show in the install dialog:

    * `assets/images/screenshots/mobile.jpg`: a 412×915 phone screen at 2x
    * `assets/images/screenshots/wide.jpg`: a 1280×800 desktop screen

  Serves `docs/` with `Site.Server` and captures it with headless Chrome
  (ChromicPDF; set `CHROME` to its path if it isn't found), so, like
  `Site.Pdf`, it is left out of the coverage report (`coveralls.json`).
  The page loads in an iframe of the exact screen size inside a larger
  Chrome window, since a window can't be narrower than 500 pixels and Chrome
  only paints what fits in it.
  """

  @port 8765
  @shots [
    {"assets/images/screenshots/mobile.jpg", {412, 915}, 2},
    {"assets/images/screenshots/wide.jpg", {1280, 800}, 1}
  ]

  @doc "Captures every screenshot into `root`. Returns the written paths."
  def build(root \\ "docs") do
    {:ok, server} =
      Bandit.start_link(plug: {Site.Server, root: root}, port: @port, startup_log: false)

    # Chrome only paints what fits its window, so the window must be larger
    # than the biggest screenshot (the window frame takes some height too)
    options = Keyword.put(chrome_options(), :chrome_args, append: "--window-size=1600,1200")
    {:ok, chrome} = Supervisor.start_link([{ChromicPDF, options}], strategy: :one_for_one)

    try do
      Enum.map(@shots, &capture(&1, root))
    after
      Supervisor.stop(chrome)
      Supervisor.stop(server)
    end
  end

  # the page loads in an iframe of the exact screen size (so its media queries
  # see that width) and the capture clips that area at the screen's scale
  defp capture({file, {width, height}, scale}, root) do
    html = """
    <html><body style="margin:0">
    <iframe src="http://localhost:#{@port}/" width="#{width}" height="#{height}" scrolling="no" style="border:0;display:block"></iframe>
    </body></html>
    """

    # loaded from a file, so the capture waits for the iframe to load
    frame = Path.join(System.tmp_dir!(), "site-screenshot-#{width}.html")
    File.write!(frame, html)

    {:ok, data} =
      ChromicPDF.capture_screenshot({:url, "file://" <> frame},
        capture_screenshot: %{
          format: "jpeg",
          quality: 85,
          captureBeyondViewport: true,
          clip: %{x: 0, y: 0, width: width, height: height, scale: scale}
        }
      )

    path = Path.join(root, file)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, Base.decode64!(data))
    path
  end

  defp chrome_options do
    case System.get_env("CHROME") do
      nil -> []
      path -> [chrome_executable: path]
    end
  end
end
