defmodule Site.Pages do
  @moduledoc "Builds the assigns for each page and renders it inside the layout."

  use Gettext, backend: Site.Gettext

  alias Site.Html
  alias Site.Locale
  alias Site.Resume
  alias Site.ResumeView
  alias Site.Templates

  @fonts_home "https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"
  @fonts_resume "https://fonts.googleapis.com/css2?family=Inter:ital,wght@0,400;0,600;1,400&display=swap"

  @doc """
  Returns `{relative_output_path, html}` for every page, in both languages.

  Pure: renders in memory and touches no files (apart from reading the
  resume data when none is given), so it can back other front ends (a Mix
  task today, maybe an MCP server later).
  """
  def all(resume \\ Resume.load!()) do
    for lang <- Locale.langs(), page <- [home(lang), resume(lang, resume)], do: page
  end

  @doc "Renders the home page in `lang` (`:en` or `:pt`)."
  def home(lang) do
    Locale.with_locale(lang, fn -> render_home(lang) end)
  end

  @doc "Renders the resume page in `lang` from the resume data."
  def resume(lang, resume) do
    Locale.with_locale(lang, fn -> render_resume(lang, resume) end)
  end

  @doc """
  Renders the HTML that is printed to the resume PDF in `lang`. Returns
  `{relative_pdf_path, html}`; `fonts_dir` is where the Inter TTF files are
  (the PDF embeds them, so it doesn't depend on Google Fonts).
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

      {Path.join(page_dir(lang, :resume), Locale.pdf_file(lang)),
       html |> Html.strip_whitespace_between_tags() |> String.trim()}
    end)
  end

  defp render_home(lang) do
    job_title = gettext("profile.job_title")

    description = gettext("home.description")

    article =
      case lang do
        :en -> Templates.home_en([])
        :pt -> Templates.home_pt([])
      end

    jsonld = Templates.jsonld_home(job_title: job_title, description: description)

    assigns =
      Map.merge(base(lang, :home), %{
        title: "Raul Pereira (raulpe7eira) - " <> job_title,
        description: description,
        og_type: "website",
        fonts_href: @fonts_home,
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
        pdf_file: Locale.pdf_file(lang)
      )

    assigns =
      Map.merge(base(lang, :resume), %{
        title: title,
        description: description,
        og_type: "profile",
        fonts_href: @fonts_resume,
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
      lang_key: Atom.to_string(lang),
      lang_code: locale.code,
      job_title: gettext("profile.job_title"),
      url: Locale.url(lang, page),
      url_en: Locale.url(:en, page),
      url_pt: Locale.url(:pt, page),
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

  defp output_file(lang, page), do: Path.join(page_dir(lang, page), "index.html")

  defp page_dir(lang, page), do: String.trim_leading(Locale.path(lang, page), "/")

  defp trim(html), do: String.trim_trailing(html, "\n")
end
