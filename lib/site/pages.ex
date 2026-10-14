defmodule Site.Pages do
  @moduledoc "Builds the assigns for each page and renders it inside the layout."

  alias Site.I18n
  alias Site.Templates

  @fonts_home "https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"

  @doc """
  Returns `{relative_output_path, html}` for every page built so far.

  Pure: renders in memory and touches no files, so it can back other
  front ends (a Mix task today, maybe an MCP server later).
  """
  def all do
    for lang <- I18n.langs(), do: home(lang)
  end

  @doc "Renders the home page in `lang` (`:en` or `:pt`)."
  def home(lang) do
    strings = I18n.get(lang)
    title = "Raul Pereira (raulpe7eira) - #{strings.job_title}"

    article =
      case lang do
        :en -> Templates.home_en([])
        :pt -> Templates.home_pt([])
      end

    jsonld =
      Templates.jsonld_home(
        job_title: strings.job_title,
        description: strings.home_description
      )

    assigns =
      Map.merge(base(lang, :home), %{
        title: title,
        description: strings.home_description,
        og_type: "website",
        fonts_href: @fonts_home,
        extra_head: "",
        jsonld: trim(jsonld),
        content: trim(article) <> "\n\n" <> trim(Templates.social([]))
      })

    {output_file(lang, :home), Templates.layout(assigns)}
  end

  defp base(lang, page) do
    strings = I18n.get(lang)
    other_strings = I18n.get(I18n.other(lang))

    %{
      lang: strings.lang,
      lang_key: Atom.to_string(lang),
      lang_code: strings.lang_code,
      job_title: strings.job_title,
      url: I18n.url(lang, page),
      url_en: I18n.url(:en, page),
      url_pt: I18n.url(:pt, page),
      og_locale: strings.og_locale,
      og_locale_alternate: other_strings.og_locale,
      page_btn_attrs: page_btn_attrs(lang, page),
      page_btn_label: strings.resume_label,
      switch_href: I18n.path(I18n.other(lang), page),
      switch_lang: other_strings.lang,
      switch_label: other_strings.switch_label,
      home_path: I18n.path(lang, :home),
      avatar_alt: strings.avatar_alt,
      subtitle: strings.subtitle,
      made_with: strings.made_with,
      by: strings.by
    }
  end

  # The toolbar switch is "on" on the resume page and links back home.
  defp page_btn_attrs(lang, :home),
    do: ~s(class="page-btn" href="#{I18n.path(lang, :resume)}" role="switch" aria-checked="false")

  defp page_btn_attrs(lang, :resume),
    do:
      ~s(class="page-btn on" href="#{I18n.path(lang, :home)}" role="switch" aria-checked="true" aria-current="page")

  defp output_file(lang, page),
    do: Path.join(String.trim_leading(I18n.path(lang, page), "/"), "index.html")

  defp trim(html), do: String.trim_trailing(html, "\n")
end
