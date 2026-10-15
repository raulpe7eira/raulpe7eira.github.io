defmodule Mix.Tasks.Site.Logo.Company do
  @shortdoc "Builds a company logo square for the resume"
  @moduledoc """
  Builds the square of a company logo (see `Site.Logo`) into
  `docs/assets/images/logos/sq-<slug>.png`, named after the company's display
  name in `data/experiences.json`.

      mix site.logo.company "R3M Tech" ~/Downloads/r3m-tech.png

  ## Options

    * `--center` - recenter a logo that is off-center in its source
  """
  use Mix.Task

  @logos "docs/assets/images/logos"

  @impl Mix.Task
  def run(args) do
    case OptionParser.parse!(args, strict: [center: :boolean]) do
      {opts, [name, source]} ->
        path = Path.join(@logos, Site.Logo.company_file(name))
        source |> Path.expand() |> Site.Logo.company_tile(opts) |> Image.write!(path)
        Mix.shell().info("wrote #{path}")

      _other ->
        Mix.raise(~s(usage: mix site.logo.company "Name" path/to/logo.png [--center]))
    end
  end
end
