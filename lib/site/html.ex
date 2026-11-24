defmodule Site.Html do
  @moduledoc "Helpers for the hand-written HTML in the templates."

  @entities %{
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "\"" => "&quot;",
    "'" => "&#x27;"
  }

  @doc "Escapes text for use in HTML content or attribute values."
  def escape(text) do
    text
    |> to_string()
    |> String.replace(Map.keys(@entities), &Map.fetch!(@entities, &1))
  end

  @doc """
  Escapes `text` and wraps the first occurrence of `part` in `<span class="hit">`,
  e.g. a recommendation's highlight inside its full text.
  """
  def mark(text, part) when is_binary(part) and part != "" do
    case String.split(to_string(text), part, parts: 2) do
      [before, rest] ->
        escape(before) <> ~s(<span class="hit">) <> escape(part) <> "</span>" <> escape(rest)

      [_whole] ->
        escape(text)
    end
  end

  def mark(text, _part), do: escape(text)

  @doc """
  Removes whitespace between tags, so templates can be indented without it
  becoming gaps between inline elements (e.g. the chips).
  """
  def strip_whitespace_between_tags(html), do: Regex.replace(~r/>\s+</, html, "><")
end
