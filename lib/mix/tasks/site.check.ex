defmodule Mix.Tasks.Site.Check do
  @shortdoc "Checks docs/ for broken local links and unused files"
  @moduledoc """
  Checks the published site for references that point to nothing and for
  assets or downloads that no page uses (see `Site.Check`), and fails
  listing them.

      mix site.check

  ## Options

    * `--root` - check another folder instead of `docs/`
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: [root: :string])
    root = Keyword.get(opts, :root, "docs")

    Mix.Task.run("compile")

    broken = Site.Check.run(root)
    unused = Site.Check.unused(root)

    for {file, reference} <- broken, do: Mix.shell().error("#{file}: #{reference}")
    for file <- unused, do: Mix.shell().error("#{file}: unused")

    case {broken, unused} do
      {[], []} ->
        Mix.shell().info("#{root}/: no broken references or unused files")

      _problems ->
        Mix.raise(
          "#{length(broken)} broken reference(s) and #{length(unused)} unused file(s) in #{root}/"
        )
    end
  end
end
