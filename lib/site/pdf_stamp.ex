defmodule Site.PdfStamp do
  @moduledoc """
  Marks each resume PDF with a hash of what it is printed from, so a stale
  PDF can be told apart without printing it again.

  The hash (`/SourceHash` in the PDF's `/Info` dictionary) covers the HTML
  printed to the PDF and the fonts it embeds. `Site.Pdf` stamps each PDF
  right after Chrome prints it; `stale/1` (run by `mix site.check`) compares
  the stamp with the hash of the current sources. Chrome's own creation
  date is left out, so printing again without changes gives the same stamp.

  The stamp is an incremental update appended to the PDF (a standard PDF
  feature): the `/Info` dictionary again, with the new key, plus a small
  cross-reference section and trailer. Stamping again appends another
  update, and the last one wins.
  """

  alias Site.Locale
  alias Site.Pages
  alias Site.Resume

  @key "SourceHash"
  # the HTML is hashed with this fonts folder, the same on every machine
  @fonts_placeholder "/fonts"

  @doc """
  Hash of what the PDF in `lang` is printed from: its HTML and the fonts in
  `fonts_dir`.
  """
  def hash(lang, resume, fonts_dir) do
    {_file, html} = Pages.resume_pdf(lang, resume, @fonts_placeholder)

    fonts =
      fonts_dir
      |> Path.join("*.woff2")
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(&File.read!/1)

    digest = :crypto.hash(:sha256, [html | fonts])
    "sha256:" <> Base.encode16(digest, case: :lower)
  end

  @doc "Returns `pdf` with `hash` stored in its `/Info` dictionary."
  def stamp(pdf, hash) do
    %{trailer: trailer, startxref: previous, info: {number, generation}} = trailer(pdf)

    dictionary =
      pdf
      |> info_dictionary(number, generation)
      |> String.replace(~r{\s*/#{@key} \([^)]*\)}, "")
      |> String.replace_suffix(">>", "\n/#{@key} (#{hash})>>")

    body = if String.ends_with?(pdf, "\n"), do: pdf, else: pdf <> "\n"
    object = "#{number} #{generation} obj\n#{dictionary}\nendobj\n"
    xref_offset = byte_size(body) + byte_size(object)
    entry = String.pad_leading("#{byte_size(body)}", 10, "0")
    trailer = String.replace(trailer, ~r{\s*/Prev \d+}, "")

    body <>
      object <>
      "xref\n#{number} 1\n#{entry} #{String.pad_leading("#{generation}", 5, "0")} n \n" <>
      "trailer\n<<#{trailer} /Prev #{previous}>>\nstartxref\n#{xref_offset}\n%%EOF\n"
  end

  @doc "Reads the hash stored by `stamp/2`, or `nil` when the PDF has none."
  def read(pdf) do
    case Regex.scan(~r{/#{@key} \((sha256:[0-9a-f]+)\)}, pdf, capture: :all_but_first) do
      [] -> nil
      found -> found |> List.last() |> hd()
    end
  end

  @doc """
  Returns the PDFs under `root` whose stamp is missing or differs from the
  hash of the current sources (they need `mix site.build`). A PDF that
  doesn't exist is left to the broken link check (`Site.Check.run/1`).
  """
  def stale(root \\ "docs", resume \\ Resume.load!()) do
    fonts_dir = Path.join(root, "assets/fonts")

    for lang <- Locale.langs(),
        file = String.trim_leading(Locale.pdf_path(lang), "/"),
        path = Path.join(root, file),
        File.exists?(path),
        stamp_of(path) != hash(lang, resume, fonts_dir),
        do: file
  end

  defp stamp_of(path), do: path |> File.read!() |> read()

  # the last trailer: its dictionary, where its cross-reference starts and
  # the /Info object it points to
  defp trailer(pdf) do
    {start, _length} = pdf |> :binary.matches("trailer") |> List.last()
    tail = binary_part(pdf, start, byte_size(pdf) - start)

    [_match, trailer, startxref] =
      Regex.run(~r{\Atrailer\s*<<(.*?)>>\s*startxref\s*(\d+)\s*%%EOF\s*\z}s, tail)

    [_match, number, generation] = Regex.run(~r{/Info (\d+) (\d+) R}, trailer)
    %{trailer: trailer, startxref: startxref, info: {number, generation}}
  end

  # the last definition of the /Info object (a later update overrides earlier ones)
  defp info_dictionary(pdf, number, generation) do
    ~r{(?:\A|\s)#{number} #{generation} obj\s*(<<.*?>>)\s*endobj}s
    |> Regex.scan(pdf, capture: :all_but_first)
    |> List.last()
    |> hd()
  end
end
