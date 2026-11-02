defmodule Site.Pdf do
  @moduledoc """
  Prints the resume PDFs, each stamped with the hash of its sources
  (`Site.PdfStamp`) so `mix site.check` can tell a stale one.

  The only part of the build that needs an external program: headless
  Chrome, through ChromicPDF (set `CHROME` to its path if it isn't found).
  CI skips it (`mix site.build --no-pdf`), so this module is left out of
  the coverage report (`coveralls.json`).
  """

  alias Site.Locale
  alias Site.Pages
  alias Site.PdfStamp

  @doc "Prints each locale's PDF under `out`. Returns the written paths."
  def build(out, resume) do
    # a cold Chrome may take longer than the 5s default to take the first job
    ChromicPDF.warm_up(chrome_options())

    options = Keyword.put(chrome_options(), :session_pool, checkout_timeout: 30_000)
    {:ok, supervisor} = Supervisor.start_link([{ChromicPDF, options}], strategy: :one_for_one)

    try do
      Enum.map(Locale.langs(), &print(&1, out, resume))
    after
      Supervisor.stop(supervisor)
    end
  end

  defp print(lang, out, resume) do
    fonts_dir = Path.expand("docs/assets/fonts")
    {file, html} = Pages.resume_pdf(lang, resume, fonts_dir)

    # printed from a file so Chrome can load the fonts from disk
    source = Path.join(System.tmp_dir!(), "site-resume-#{lang}.html")
    File.write!(source, html)

    pdf = Path.join(out, file)
    File.mkdir_p!(Path.dirname(pdf))

    :ok =
      ChromicPDF.print_to_pdf({:url, "file://" <> source},
        output: pdf,
        print_to_pdf: %{preferCSSPageSize: true, printBackground: true}
      )

    stamped = pdf |> File.read!() |> PdfStamp.stamp(PdfStamp.hash(lang, resume, fonts_dir))
    File.write!(pdf, stamped)
    pdf
  end

  defp chrome_options do
    case System.get_env("CHROME") do
      nil -> []
      path -> [chrome_executable: path]
    end
  end
end
