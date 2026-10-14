defmodule Site do
  @moduledoc """
  Static site generator for raulpe7eira.tech.

  `Site.Pages` renders every page in memory; `build/2` writes them (and,
  optionally, the resume PDFs via `Site.Pdf`). Output goes to `docs/`, the
  folder GitHub Pages serves.
  """

  alias Site.Pages
  alias Site.Pdf
  alias Site.Resume

  @out "docs"

  @doc """
  Renders all pages and writes them under `out`. Returns the written paths.

  ## Options

    * `:pdf` - also print the resume PDFs (needs Chrome). Defaults to `false`.
  """
  def build(out \\ @out, opts \\ []) do
    resume = Resume.load!()

    pages =
      for {file, html} <- Pages.all(resume) do
        path = Path.join(out, file)
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, html)
        path
      end

    if Keyword.get(opts, :pdf, false), do: pages ++ Pdf.build(out, resume), else: pages
  end
end
