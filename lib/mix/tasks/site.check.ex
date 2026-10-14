defmodule Mix.Tasks.Site.Check do
  @shortdoc "Checks docs/ for broken local links"
  @moduledoc """
  Checks the published site for references that point to nothing (see
  `Site.Check`), and fails listing them.

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

    case Site.Check.run(root) do
      [] ->
        Mix.shell().info("#{root}/: no broken references")

      broken ->
        for {file, reference} <- broken, do: Mix.shell().error("#{file}: #{reference}")
        Mix.raise("#{length(broken)} broken reference(s) in #{root}/")
    end
  end
end
