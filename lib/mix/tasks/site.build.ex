defmodule Mix.Tasks.Site.Build do
  @shortdoc "Generates the site into docs/"
  @moduledoc """
  Generates the static pages and the resume PDFs into `docs/`, the folder
  GitHub Pages serves.

      mix site.build

  Printing the PDFs needs Chrome; see `Site.Pdf`.

  ## Options

    * `--output` - write somewhere else instead of `docs/`
    * `--no-pdf` - skip the PDFs (CI uses it: no Chrome
      there, and Chrome stamps each PDF with its creation date)
  """
  use Mix.Task

  @switches [output: :string, pdf: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: @switches)

    # starts the dependencies too (ChromicPDF needs :telemetry running)
    Mix.Task.run("app.start")

    out = Keyword.get(opts, :output, "docs")

    for path <- Site.build(out, pdf: Keyword.get(opts, :pdf, true)) do
      Mix.shell().info("wrote #{path}")
    end
  end
end
