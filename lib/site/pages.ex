defmodule Site.Pages do
  @moduledoc "Builds the assigns for each page and renders it inside the layout."

  use Gettext, backend: Site.Gettext

  alias Site.Html
  alias Site.Locale
  alias Site.Resume
  alias Site.ResumeView
  alias Site.Templates

  @sitemap_pages [:home, :resume]

  @doc """
  Returns `{relative_output_path, content}` for every page, in both
  languages, plus `llms.txt` and `404.html`. The sitemap is separate
  (`sitemap/1`): its dates depend on what is already published.

  Pure: renders in memory and touches no files (apart from reading the
  resume data when none is given), so it can back other front ends (a Mix
  task today, maybe an MCP server later).
  """
  def all(resume \\ Resume.load!()) do
    pages = for lang <- Locale.langs(), page <- [home(lang), resume(lang, resume)], do: page
    pages ++ [llms(resume), not_found()]
  end

  @doc "`{output_path, url}` of every page listed in the sitemap, in sitemap order."
  def sitemap_pages do
    for page <- @sitemap_pages,
        lang <- Locale.langs(),
        do: {output_file(lang, page), Locale.url(lang, page)}
  end

  @doc """
  Renders `sitemap.xml`. `lastmods` maps each page URL to the date the page
  last changed (`Site.build/2` works it out).
  """
  def sitemap(lastmods) do
    entries =
      for page <- @sitemap_pages, lang <- Locale.langs() do
        url = Locale.url(lang, page)
        %{url: url, lastmod: Map.fetch!(lastmods, url), alternates: alternates(page)}
      end

    {"sitemap.xml", Templates.sitemap(entries: entries)}
  end

  @doc "Renders `llms.txt`, the plain-text summary of the site for LLMs (English only)."
  def llms(resume) do
    text =
      Templates.llms(
        base_url: Locale.base_url(),
        home_pt_br: Locale.url(:pt_br, :home),
        resume_en_us: Locale.url(:en_us, :resume),
        resume_pt_br: Locale.url(:pt_br, :resume),
        pdf_en_us: Locale.base_url() <> Locale.pdf_path(:en_us),
        pdf_pt_br: Locale.base_url() <> Locale.pdf_path(:pt_br),
        highlights: resume.highlights.en_us
      )

    {"llms.txt", text}
  end

  @doc "Renders `404.html`, which sends unknown addresses to the home page of their language."
  def not_found do
    [default | _others] = Locale.langs()

    homes =
      Locale.langs()
      |> Enum.map(&Locale.path(&1, :home))
      |> Enum.reject(&(&1 == "/"))

    {"404.html", Templates.not_found(lang: Locale.get(default).lang, homes: JSON.encode!(homes))}
  end

  @doc "Renders the home page in `lang` (`:en_us` or `:pt_br`)."
  def home(lang) do
    Locale.with_locale(lang, fn -> render_home(lang) end)
  end

  @doc "Renders the resume page in `lang` from the resume data."
  def resume(lang, resume) do
    Locale.with_locale(lang, fn -> render_resume(lang, resume) end)
  end

  @doc """
  Renders the HTML that is printed to the resume PDF in `lang`. Returns
  `{relative_pdf_path, html}`; `fonts_dir` is where the Inter WOFF2 files are
  (`docs/assets/fonts/`, the same the site serves; the PDF embeds them).
  """
  def resume_pdf(lang, resume, fonts_dir) do
    Locale.with_locale(lang, fn ->
      view = ResumeView.build(resume, lang)

      html =
        Templates.resume_pdf(
          lang: Locale.get(lang).lang,
          title: view.name <> " - " <> gettext("resume.title"),
          job_title: gettext("profile.job_title"),
          fonts_dir: fonts_dir,
          view: view
        )

      {String.trim_leading(Locale.pdf_path(lang), "/"),
       html |> Html.strip_whitespace_between_tags() |> String.trim()}
    end)
  end

  defp render_home(lang) do
    job_title = gettext("profile.job_title")

    description = gettext("home.description")

    article =
      case lang do
        :en_us -> Templates.home_en_us([])
        :pt_br -> Templates.home_pt_br([])
      end

    jsonld = Templates.jsonld_home(job_title: job_title, description: description)

    assigns =
      Map.merge(base(lang, :home), %{
        title: "Raul Pereira (raulpe7eira) - " <> job_title,
        description: description,
        og_type: "website",
        extra_head: "",
        jsonld: trim(jsonld),
        content: trim(article) <> "\n\n" <> trim(Templates.social([]))
      })

    {output_file(lang, :home), Templates.layout(assigns)}
  end

  defp render_resume(lang, resume) do
    title = "Raul Pereira (raulpe7eira) - " <> gettext("resume.title")
    description = gettext("resume.description")

    jsonld =
      Templates.jsonld_resume(
        url: Locale.url(lang, :resume),
        title: title,
        lang: Locale.get(lang).lang,
        description: description,
        job_title: gettext("profile.job_title")
      )

    section =
      Templates.resume(
        view: ResumeView.build(resume, lang),
        job_title: gettext("profile.job_title"),
        home_path: Locale.path(lang, :home),
        pdf_path: Locale.pdf_path(lang),
        pdf_download_name: Locale.pdf_download_name(lang)
      )

    assigns =
      Map.merge(base(lang, :resume), %{
        title: title,
        description: description,
        og_type: "profile",
        extra_head: ~s(  <link rel="stylesheet" href="/assets/css/resume.css" />\n),
        jsonld: trim(jsonld),
        content: "    " <> (section |> Html.strip_whitespace_between_tags() |> String.trim())
      })

    {output_file(lang, :resume), Templates.layout(assigns)}
  end

  defp base(lang, page) do
    locale = Locale.get(lang)
    other = Locale.other(lang)
    other_locale = Locale.get(other)

    %{
      lang: locale.lang,
      lang_key: String.downcase(locale.lang),
      lang_code: locale.code,
      job_title: gettext("profile.job_title"),
      url: Locale.url(lang, page),
      url_en_us: Locale.url(:en_us, page),
      url_pt_br: Locale.url(:pt_br, page),
      og_locale: locale.og_locale,
      og_locale_alternate: other_locale.og_locale,
      page_btn_attrs: page_btn_attrs(lang, page),
      page_btn_label: gettext("toolbar.resume"),
      switch_href: Locale.path(other, page),
      switch_lang: other_locale.lang,
      # the switch is labeled in the language it switches to
      switch_label: Locale.with_locale(other, fn -> gettext("toolbar.switch_language") end),
      home_path: Locale.path(lang, :home),
      avatar_alt: gettext("header.avatar_alt"),
      subtitle: gettext("header.subtitle"),
      made_with: gettext("footer.made_with"),
      by: gettext("footer.by")
    }
  end

  # The toolbar switch is off on the home and links to the resume;
  # on the resume it is on and links back home.
  defp page_btn_attrs(lang, :home),
    do:
      ~s(class="page-btn" href="#{Locale.path(lang, :resume)}" role="switch" aria-checked="false")

  defp page_btn_attrs(lang, :resume),
    do:
      ~s(class="page-btn on" href="#{Locale.path(lang, :home)}" role="switch" aria-checked="true" aria-current="page")

  # every locale, plus x-default pointing to the default (first) one
  defp alternates(page) do
    [default | _others] = Locale.langs()
    links = for lang <- Locale.langs(), do: {Locale.get(lang).lang, Locale.url(lang, page)}
    links ++ [{"x-default", Locale.url(default, page)}]
  end

  defp output_file(lang, page), do: Path.join(page_dir(lang, page), "index.html")

  defp page_dir(lang, page), do: String.trim_leading(Locale.path(lang, page), "/")

  defp trim(html), do: String.trim_trailing(html, "\n")
end
