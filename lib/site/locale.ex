defmodule Site.Locale do
  @moduledoc """
  Per-locale settings: paths, URLs and codes. Text lives in `Site.Gettext`.

  Locales are always full (`:en_us`, `:pt_br`); only the visible button
  shows the short code. In URLs the short prefix is the language with its
  default country: English (US) is the root `/` and Portuguese (Brazil) is
  `/pt/`; another variant would get the full code (e.g. `/pt-pt/`).
  """

  @base_url "https://raulpe7eira.tech"

  @locales %{
    en_us: %{
      lang: "en-US",
      gettext: "en_US",
      code: "EN",
      prefix: "/",
      og_locale: "en_US",
      pdf_download_name: "raul-pereira-da-silva-resume.pdf"
    },
    pt_br: %{
      lang: "pt-BR",
      gettext: "pt_BR",
      code: "PT",
      prefix: "/pt/",
      og_locale: "pt_BR",
      pdf_download_name: "raul-pereira-da-silva-curriculo.pdf"
    }
  }

  @doc "Supported locales, default first."
  def langs, do: [:en_us, :pt_br]

  @doc "Site origin, without a trailing slash."
  def base_url, do: @base_url

  @doc "Settings for `lang`."
  def get(lang), do: Map.fetch!(@locales, lang)

  @doc "The other locale (target of the EN/PT switch)."
  def other(:en_us), do: :pt_br
  def other(:pt_br), do: :en_us

  @doc "Site path of `page` (:home | :resume) in `lang`."
  def path(lang, :home), do: get(lang).prefix
  def path(lang, :resume), do: get(lang).prefix <> "resume/"

  @doc "Absolute URL of `page` in `lang`."
  def url(lang, page), do: @base_url <> path(lang, page)

  @doc ~S|Site path of the resume PDF in `lang`, e.g. "/downloads/raul-pereira-da-silva-resume-en-us.pdf".|
  def pdf_path(lang),
    do: "/downloads/raul-pereira-da-silva-resume-" <> String.downcase(get(lang).lang) <> ".pdf"

  @doc "File name the browser saves the resume PDF in `lang` as."
  def pdf_download_name(lang), do: get(lang).pdf_download_name

  @doc "Runs `fun` with the Gettext locale of `lang`, returning its result."
  def with_locale(lang, fun), do: Gettext.with_locale(Site.Gettext, get(lang).gettext, fun)
end
