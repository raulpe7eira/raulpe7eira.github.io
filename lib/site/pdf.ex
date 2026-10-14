defmodule Site.Pdf do
  @moduledoc """
  Prints the resume PDFs and their thumbnails.

  The only part of the build that needs external programs: headless Chrome
  (through ChromicPDF; set `CHROME` to its path if it isn't found) and
  `pdftoppm` (poppler). CI skips it (`mix site.build --no-pdf`), so this
  module is left out of the coverage report (`coveralls.json`).
  """

  alias Site.Locale
  alias Site.Pages

  # thumb.png: top of the first page, shown at half this size (sharp on HiDPI screens)
  @thumb_width 155
  @thumb_height 136

  @doc "Prints each language's PDF and thumbnail under `out`. Returns the written paths."
  def build(out, resume) do
    System.find_executable("pdftoppm") ||
      raise "pdftoppm not found: install poppler (e.g. brew install poppler) or use --no-pdf"

    # a cold Chrome may take longer than the 5s default to take the first job
    ChromicPDF.warm_up(chrome_options())

    options = Keyword.put(chrome_options(), :session_pool, checkout_timeout: 30_000)
    {:ok, supervisor} = Supervisor.start_link([{ChromicPDF, options}], strategy: :one_for_one)

    try do
      Enum.flat_map(Locale.langs(), &print(&1, out, resume))
    after
      Supervisor.stop(supervisor)
    end
  end

  defp print(lang, out, resume) do
    {file, html} = Pages.resume_pdf(lang, resume, Application.app_dir(:site, "priv/fonts"))

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

    thumb = Path.join(Path.dirname(pdf), "thumb.png")
    thumbnail!(pdf, thumb)

    [pdf, thumb]
  end

  defp thumbnail!(pdf, thumb) do
    args =
      ~w(-f 1 -l 1 -singlefile -png -scale-to-x #{@thumb_width} -scale-to-y -1) ++
        ~w(-x 0 -y 0 -W #{@thumb_width} -H #{@thumb_height}) ++ [pdf, Path.rootname(thumb)]

    {_output, 0} = System.cmd("pdftoppm", args, stderr_to_stdout: true)
  end

  defp chrome_options do
    case System.get_env("CHROME") do
      nil -> []
      path -> [chrome_executable: path]
    end
  end
end
