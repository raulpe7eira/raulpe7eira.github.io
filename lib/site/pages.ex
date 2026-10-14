defmodule Site.Pages do
  @moduledoc "Builds the assigns for each page and renders it inside the layout."

  use Gettext, backend: Site.Gettext

  alias Site.Locale
  alias Site.Templates

  @fonts_home "https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"

  @doc """
  Returns `{relative_output_path, html}` for every page built so far.

  Pure: renders in memory and touches no files, so it can back other
  front ends (a Mix task today, maybe an MCP server later).
  """
  def all do
    for lang <- Locale.langs(), do: home(lang)
  end

  @doc "Renders the home page in `lang` (`:en` or `:pt`)."
  def home(lang) do
    Locale.with_locale(lang, fn -> render_home(lang) end)
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

  # The toolbar switch is off on the home and links to the resume.
  # The resume page will add an "on" clause that links back home.
  defp page_btn_attrs(lang, :home),
    do:
      ~s(class="page-btn" href="#{Locale.path(lang, :resume)}" role="switch" aria-checked="false")

  defp output_file(lang, page),
    do: Path.join(String.trim_leading(Locale.path(lang, page), "/"), "index.html")

  defp trim(html), do: String.trim_trailing(html, "\n")
end
