defmodule Site.Check do
  @moduledoc """
  Finds broken local references in the published site (`docs/`):

    * `href`, `src` and path-like `content` attributes in HTML
    * `url(...)` in CSS
    * site URLs in `sitemap.xml` and `llms.txt`, and `src` paths in XML
    * paths in JSON (the favicon manifest)
    * `#id`s used from SVG files (the icon sprite)

  External links are not checked (no network). A reference to a folder
  points to its `index.html`, as on GitHub Pages.
  """

  alias Site.Locale

  @extensions "{html,css,xml,txt,json}"

  @doc "Returns `{file, reference}` for every reference under `root` that points to nothing."
  def run(root \\ "docs") do
    for file <- files(root),
        reference <- references(file),
        not exists?(root, file, reference) do
      {Path.relative_to(file, root), reference}
    end
  end

  defp files(root), do: root |> Path.join("**/*.#{@extensions}") |> Path.wildcard() |> Enum.sort()

  defp references(file) do
    text = File.read!(file)

    case Path.extname(file) do
      ".html" -> html_references(text)
      ".css" -> scan(~r/url\(\s*['"]?([^'")]+)['"]?\s*\)/, text)
      ".json" -> text |> JSON.decode!() |> json_paths()
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
