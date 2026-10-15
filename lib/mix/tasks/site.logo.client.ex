defmodule Mix.Tasks.Site.Logo.Client do
  @shortdoc "Builds a client/project logo tile for the resume"
  @moduledoc """
  Builds the tile of a client or project logo (see `Site.Logo`) into
  `docs/assets/images/logos/cl-<slug>.png`, named after the reference in
  `data/experiences.json`.

      mix site.logo.client "Total Bank" ~/Downloads/hd-total-bank.png

  ## Options

    * `--boost` - enlarge a logo that looks small (e.g. `1.25`, `1.6`)
  """
  use Mix.Task

  @logos "docs/assets/images/logos"

  @impl Mix.Task
  def run(args) do
    case OptionParser.parse!(args, strict: [boost: :float]) do
      {opts, [name, source]} ->
        path = Path.join(@logos, Site.Logo.client_file(name))
        source |> Path.expand() |> Site.Logo.client_tile(opts) |> Image.write!(path)
        Mix.shell().info("wrote #{path}")

      _other ->
        Mix.raise(~s(usage: mix site.logo.client "Name" path/to/logo.png [--boost 1.25]))
    end
  end
end
