defmodule Site.Check do
  @moduledoc """
  Finds broken local references in the published site (`docs/`):

    * `href`, `src` and path-like `content` attributes in HTML
    * `url(...)` in CSS
    * site URLs in `sitemap.xml` and `llms.txt`, and `src` paths in XML
    * paths in JSON (the web manifest)
    * `#id`s used from SVG files (the icon sprite)

  External links are not checked (no network). A reference to a folder
  points to its `index.html`, as on GitHub Pages.

  It also finds unused files: assets and downloads that no page reaches,
  directly or through a stylesheet, manifest or other file the pages use.
  The fonts count as used, since the PDF resume embeds them.
  """

  alias Site.Locale

  @extensions "{html,css,xml,txt,json,webmanifest}"
  @text_extensions ~w(.html .css .xml .txt .json .webmanifest)
  @published "{assets,downloads}"
  @pdf_fonts "assets/fonts"

  @doc "Returns `{file, reference}` for every reference under `root` that points to nothing."
  def run(root \\ "docs") do
    for file <- files(root),
        reference <- references(file),
        not exists?(root, file, reference) do
      {Path.relative_to(file, root), reference}
    end
  end

  @doc "Returns every file under `assets/` and `downloads/` that no page reaches."
  def unused(root \\ "docs") do
    used = reach(root, entries(root), MapSet.new())
    fonts = root |> Path.join(@pdf_fonts) |> Path.expand()

    unused =
      for file <- root |> Path.join("#{@published}/**/*") |> Path.wildcard(),
          File.regular?(file),
          path = Path.expand(file),
          not MapSet.member?(used, path),
          not String.starts_with?(path, fonts <> "/"),
          do: Path.relative_to(file, root)

    Enum.sort(unused)
  end

  # the pages and the other files at the site's top level
  defp entries(root) do
    published = root |> Path.join(@published) |> Path.wildcard() |> Enum.map(&(&1 <> "/"))

    for file <- files(root),
        not Enum.any?(published, &String.starts_with?(file, &1)),
        do: Path.expand(file)
  end

  defp reach(_root, [], used), do: used

  defp reach(root, [file | rest], used) do
    if MapSet.member?(used, file),
      do: reach(root, rest, used),
      else: reach(root, targets(root, file) ++ rest, MapSet.put(used, file))
  end

  defp targets(root, file) do
    if Path.extname(file) in @text_extensions do
      for reference <- references(file),
          {path, _fragment} = split(reference),
          target = root |> resolve(file, path) |> Path.expand(),
          File.regular?(target),
          do: target
    else
      []
    end
  end

  defp files(root), do: root |> Path.join("**/*.#{@extensions}") |> Path.wildcard() |> Enum.sort()

  defp references(file) do
    text = File.read!(file)

    case Path.extname(file) do
      ".html" -> html_references(text)
      ".css" -> scan(~r/url\(\s*['"]?([^'")]+)['"]?\s*\)/, text)
      json when json in [".json", ".webmanifest"] -> text |> JSON.decode!() |> json_paths()
      _xml_or_txt -> site_urls(text) ++ scan(~r/\ssrc="(\/[^"]*)"/, text)
    end
  end

  # `content` holds text too (descriptions, colors), so only paths and site URLs count there
  defp html_references(text) do
    for [attribute, value] <-
          Regex.scan(~r/\s(href|src|content)="([^"]+)"/, text, capture: :all_but_first),
        local?(attribute, value),
        do: value
  end

  defp local?("content", value), do: site_path?(value)

  defp local?(_attribute, value) do
    site_path?(value) or
      (not String.contains?(value, ":") and not String.starts_with?(value, "#"))
  end

  defp site_path?(value) do
    String.starts_with?(value, Locale.base_url()) or
      (String.starts_with?(value, "/") and not String.starts_with?(value, "//"))
  end

  defp site_urls(text),
    do: List.flatten(Regex.scan(~r{#{Regex.escape(Locale.base_url())}[^\s"<>)]*}, text))

  defp json_paths(value) when is_map(value), do: value |> Map.values() |> json_paths()
  defp json_paths(value) when is_list(value), do: Enum.flat_map(value, &json_paths/1)
  defp json_paths("/" <> _rest = path), do: [path]
  defp json_paths(_value), do: []

  defp scan(regex, text), do: regex |> Regex.scan(text, capture: :all_but_first) |> List.flatten()

  defp exists?(root, file, reference) do
    {path, fragment} = split(reference)
    target = resolve(root, file, path)

    File.regular?(target) and fragment_exists?(target, fragment)
  end

  defp split(reference) do
    [path | fragment] =
      reference
      |> String.replace_prefix(Locale.base_url(), "")
      |> String.split("#", parts: 2)

    {path |> String.split("?") |> hd() |> URI.decode(), List.first(fragment)}
  end

  defp resolve(root, file, path) do
    target =
      cond do
        path == "" -> root
        String.starts_with?(path, "/") -> Path.join(root, path)
        true -> Path.join(Path.dirname(file), path)
      end

    if File.dir?(target), do: Path.join(target, "index.html"), else: target
  end

  defp fragment_exists?(_target, nil), do: true

  defp fragment_exists?(target, fragment) do
    Path.extname(target) != ".svg" or File.read!(target) =~ ~s(id="#{fragment}")
  end
end
