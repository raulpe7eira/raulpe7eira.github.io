defmodule Mix.Tasks.Site.Server do
  @shortdoc "Builds the site, serves docs/ at http://localhost:8000 and rebuilds on changes"
  @moduledoc """
  Builds the site (`mix site.build`) and serves `docs/` locally, the way
  GitHub Pages serves it (see `Site.Server`), to check the result by hand.

  While it runs, it watches the sources (see `Site.LiveReload.Watcher`): a
  change in `data/`, `lib/` or `priv/` rebuilds the site, a change in
  `docs/assets/` doesn't need to, and the open pages reload by themselves
  (see `Site.LiveReload.Plug`).

      mix site.server

  ## Options

    * `--port` - port to listen on (default `8000`)
    * `--no-pdf` - build (and rebuild) without the PDFs; the current ones are kept
    * `--no-build` - serve `docs/` as it is, without building first
    * `--no-watch` - don't watch the sources nor reload the pages

  Stop it with Ctrl+C twice.
  """
  use Mix.Task

  alias Site.LiveReload.Watcher

  @switches [port: :integer, build: :boolean, pdf: :boolean, watch: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: @switches)
    pdf = Keyword.get(opts, :pdf, true)

    if Keyword.get(opts, :build, true) do
      Mix.Task.run("site.build", if(pdf, do: [], else: ["--no-pdf"]))
    end

    Mix.Task.run("app.start")

    port = Keyword.get(opts, :port, 8000)
    plug = plug(Keyword.get(opts, :watch, true), pdf)
    {:ok, _server} = Bandit.start_link(plug: plug, port: port)
    Mix.shell().info("Serving docs/ at http://localhost:#{port} (Ctrl+C twice to stop)")

    Process.sleep(:infinity)
  end

  defp plug(true, pdf) do
    {:ok, _watcher} = Watcher.start_link(pdf: pdf)
    Mix.shell().info("Watching data/, lib/, priv/ and docs/assets/ for changes")
    {Site.LiveReload.Plug, root: "docs", version: &Watcher.version/0}
  end

  defp plug(false, _pdf), do: {Site.Server, root: "docs"}
end
