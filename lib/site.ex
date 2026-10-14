defmodule Site do
  @moduledoc """
  Static site generator for raulpe7eira.tech.

  `Site.Pages` renders every page in memory; `build/1` is the only function
  that writes files. Output goes to `docs/`, the folder GitHub Pages serves.
  """

  alias Site.Pages

  @out "docs"

  @doc "Renders all pages and writes them under `out`. Returns the written paths."
  def build(out \\ @out) do
    for {file, html} <- Pages.all() do
      path = Path.join(out, file)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, html)
      path
    end
  end
end
