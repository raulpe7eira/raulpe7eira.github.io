defmodule Mix.Tasks.Site.Icons do
  @shortdoc "Builds the favicons and the avatar from a photo"
  @moduledoc """
  Builds the site icons and the avatar (see `Site.Icons`) into `docs/` from
  one square photo.

      mix site.icons ~/Downloads/raul-photo.jpg
  """
  use Mix.Task

  @docs "docs"

  @impl Mix.Task
  def run(args) do
    case args do
      [source] ->
        for {file, binary} <- source |> Path.expand() |> Site.Icons.build() do
          path = Path.join(@docs, file)
          File.mkdir_p!(Path.dirname(path))
          File.write!(path, binary)
          Mix.shell().info("wrote #{path}")
        end

      _other ->
        Mix.raise("usage: mix site.icons path/to/photo.jpg")
    end
  end
end
