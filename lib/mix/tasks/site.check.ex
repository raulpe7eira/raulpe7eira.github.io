defmodule Mix.Tasks.Site.Check do
  @shortdoc "Checks docs/ for broken local links, unused files and stale PDFs"
  @moduledoc """
  Checks the published site for references that point to nothing, for
  assets or downloads that no page uses (see `Site.Check`) and for resume
  PDFs printed from older sources (see `Site.PdfStamp`), and fails listing
  them.

      mix site.check

  ## Options

    * `--root` - check another folder instead of `docs/`
  """
  use Mix.Task

  alias Site.PdfStamp

  @impl Mix.Task
  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: [root: :string])
    root = Keyword.get(opts, :root, "docs")

    Mix.Task.run("compile")

    broken = Site.Check.run(root)
    unused = Site.Check.unused(root)
    stale = PdfStamp.stale(root)

    for {file, reference} <- broken, do: Mix.shell().error("#{file}: #{reference}")
    for file <- unused, do: Mix.shell().error("#{file}: unused")
    for file <- stale, do: Mix.shell().error("#{file}: out of date, run `mix site.build`")

    case {broken, unused, stale} do
      {[], [], []} ->
        Mix.shell().info("#{root}/: no broken references, unused files or stale PDFs")

      _problems ->
        Mix.raise(
          "#{length(broken)} broken reference(s), #{length(unused)} unused file(s) " <>
            "and #{length(stale)} stale PDF(s) in #{root}/"
        )
    end
  end
end
