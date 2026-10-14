defmodule Mix.Tasks.Site.Build do
  @shortdoc "Generates the site into docs/"
  @moduledoc """
  Generates the static pages into `docs/`, the folder GitHub Pages serves.

      mix site.build

  ## Options

    * `--output` - write somewhere else instead of `docs/`
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: [output: :string])

    Mix.Task.run("compile")

    for path <- Site.build(Keyword.get(opts, :output, "docs")) do
      Mix.shell().info("wrote #{path}")
    end
  end
end
