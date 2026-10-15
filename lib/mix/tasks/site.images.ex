defmodule Mix.Tasks.Site.Images do
  @shortdoc "Builds the site images: logos, favicons, avatar and screenshots"
  @moduledoc """
  Builds the site images into `docs/`. The first argument is the kind of
  image, which decides the other arguments and how the image looks:

      mix site.images company "Name" path/to/logo.png [--center]
      mix site.images client "Name" path/to/logo.png [--boost 1.25]
      mix site.images project "Name" path/to/logo.png [--boost 1.25]
      mix site.images favicons path/to/photo.jpg
      mix site.images avatar path/to/photo.jpg
      mix site.images screenshots

    * `company` - square employer logo on the resume timeline,
      `sq-<slug>.png` (see `Site.Logo`); `--center` recenters a logo that is
      off-center in its source
    * `client`, `project` - client/project tile on the resume, `cl-<slug>.png`
      (see `Site.Logo`); `--boost` enlarges a logo that looks small
    * `favicons` - favicons and app icons from my photo (see `Site.Photo`)
    * `avatar` - the home page photo, from my photo (see `Site.Photo`)
    * `screenshots` - home page screenshots for the web manifest, captured
      with headless Chrome (see `Site.Screenshots`)

  The name is the one in `data/` (company display name, client or project
  name), so the file matches what the resume looks for.
  """
  use Mix.Task

  @docs "docs"
  @logos "docs/assets/images/logos"

  @usage """
  usage:
    mix site.images company "Name" path/to/logo.png [--center]
    mix site.images client "Name" path/to/logo.png [--boost 1.25]
    mix site.images project "Name" path/to/logo.png [--boost 1.25]
    mix site.images favicons path/to/photo.jpg
    mix site.images avatar path/to/photo.jpg
    mix site.images screenshots
  """

  @impl Mix.Task
  def run(args) do
    case args do
      [] -> Mix.shell().info(@usage)
      ["company" | rest] -> company(rest)
      [kind | rest] when kind in ["client", "project"] -> client(rest)
      ["favicons", source] -> photo(source, &Site.Photo.favicons/1)
      ["avatar", source] -> photo(source, &Site.Photo.avatar/1)
      ["screenshots"] -> screenshots()
      _other -> Mix.raise(@usage)
    end
  end

  defp company(args) do
    case OptionParser.parse!(args, strict: [center: :boolean]) do
      {opts, [name, source]} ->
        write_logo(
          Site.Logo.company_file(name),
          Site.Logo.company_tile(Path.expand(source), opts)
        )

      _other ->
        Mix.raise(@usage)
    end
  end

  defp client(args) do
    case OptionParser.parse!(args, strict: [boost: :float]) do
      {opts, [name, source]} ->
        write_logo(Site.Logo.client_file(name), Site.Logo.client_tile(Path.expand(source), opts))

      _other ->
        Mix.raise(@usage)
    end
  end

  defp write_logo(file, image) do
    path = Path.join(@logos, file)
    Image.write!(image, path)
    Mix.shell().info("wrote #{path}")
  end

  defp photo(source, build) do
    for {file, binary} <- build.(Path.expand(source)) do
      path = Path.join(@docs, file)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, binary)
      Mix.shell().info("wrote #{path}")
    end
  end

  defp screenshots do
    Mix.Task.run("app.start")

    for path <- Site.Screenshots.build(@docs) do
      Mix.shell().info("wrote #{path}")
    end
  end
end
