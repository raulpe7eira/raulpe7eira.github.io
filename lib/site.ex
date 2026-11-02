defmodule Site do
  @moduledoc """
  Static site generator for raulpe7eira.tech.

  `Site.Pages` renders every page in memory; `build/2` writes them (and,
  optionally, the resume PDFs via `Site.Pdf`). Output goes to `docs/`, the
  folder GitHub Pages serves.
  """

  alias Site.Pages
  alias Site.Pdf
  alias Site.Resume

  @out "docs"
  @security_renew_days 30

  @doc """
  Renders all pages and writes them under `out`. Returns the written paths.

  The sitemap's `lastmod` of a page is `today` only when its HTML differs
  from the file already in `out`; otherwise the date in the current
  sitemap is kept. So rebuilding without changes changes nothing (which is
  what CI checks).

  The `Expires` of `security.txt` works the same way: it is kept until
  fewer than #{@security_renew_days} days are left, then moves to a year from `today`.
  So, a month before it expires, CI finds `docs/` out of date: rebuilding
  renews it.

  ## Options

    * `:pdf` - also print the resume PDFs (needs Chrome). Defaults to `false`.
    * `:today` - the date for pages that changed (and the renewal of
      `security.txt`). Defaults to `Date.utc_today/0`.
  """
  def build(out \\ @out, opts \\ []) do
    resume = Resume.load!()
    files = Pages.all(resume)
    today = Keyword.get_lazy(opts, :today, &Date.utc_today/0)

    sitemap = Pages.sitemap(lastmods(out, files, today))
    security = Pages.security(security_expires(out, today))

    written =
      for {file, content} <- files ++ [sitemap, security] do
        path = Path.join(out, file)
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, content)
        path
      end

    if Keyword.get(opts, :pdf, false), do: written ++ Pdf.build(out, resume), else: written
  end

  defp lastmods(out, files, today) do
    previous = previous_lastmods(out)
    contents = Map.new(files)

    Map.new(Pages.sitemap_pages(), fn {file, url} ->
      unchanged? = File.read(Path.join(out, file)) == {:ok, Map.fetch!(contents, file)}
      {url, if(unchanged?, do: Map.get(previous, url, today), else: today)}
    end)
  end

  # keeps the current Expires while it has at least @security_renew_days
  # left; otherwise (or with no file yet) a year from today, at midnight UTC
  defp security_expires(out, today) do
    renewed = DateTime.new!(Date.add(today, 365), ~T[00:00:00], "Etc/UTC")

    case current_security_expires(out) do
      {:ok, expires} ->
        if Date.diff(DateTime.to_date(expires), today) >= @security_renew_days,
          do: expires,
          else: renewed

      :error ->
        renewed
    end
  end

  defp current_security_expires(out) do
    with {:ok, text} <- File.read(Path.join(out, ".well-known/security.txt")),
         [_line, value] <- Regex.run(~r/^Expires: (.+)$/m, text),
         {:ok, expires, 0} <- DateTime.from_iso8601(value) do
      {:ok, expires}
    else
      _other -> :error
    end
  end

  defp previous_lastmods(out) do
    case File.read(Path.join(out, "sitemap.xml")) do
      {:ok, xml} ->
        ~r{<loc>([^<]+)</loc>.*?<lastmod>([^<]+)</lastmod>}s
        |> Regex.scan(xml, capture: :all_but_first)
        |> Map.new(fn [url, date] -> {url, Date.from_iso8601!(date)} end)

      {:error, :enoent} ->
        %{}
    end
  end
end
