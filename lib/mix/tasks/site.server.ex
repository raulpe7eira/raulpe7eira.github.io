defmodule Mix.Tasks.Site.Server do
  @shortdoc "Builds the site and serves docs/ at http://localhost:8000"
  @moduledoc """
  Builds the site (`mix site.build`) and serves `docs/` locally, the way
  GitHub Pages serves it (see `Site.Server`), to check the result by hand.

      mix site.server

  ## Options

    * `--port` - port to listen on (default `8000`)
    * `--no-pdf` - build without the PDFs (faster; the current ones are kept)
    * `--no-build` - serve `docs/` as it is, without building

  Stop it with Ctrl+C twice.
  """
  use Mix.Task

  @switches [port: :integer, build: :boolean, pdf: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: @switches)

    if Keyword.get(opts, :build, true) do
      build_args = if Keyword.get(opts, :pdf, true), do: [], else: ["--no-pdf"]
      Mix.Task.run("site.build", build_args)
    end

    Mix.Task.run("app.start")

    port = Keyword.get(opts, :port, 8000)
    {:ok, _server} = Bandit.start_link(plug: {Site.Server, root: "docs"}, port: port)
    Mix.shell().info("Serving docs/ at http://localhost:#{port} (Ctrl+C twice to stop)")

    Process.sleep(:infinity)
  end
end
