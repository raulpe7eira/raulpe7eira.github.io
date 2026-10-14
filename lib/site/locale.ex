defmodule Site.Locale do
  @moduledoc "Per-language settings: paths, URLs and locale codes. Text lives in `Site.Gettext`."

  @base_url "https://raulpe7eira.tech"

  @locales %{
    en: %{lang: "en", gettext: "en", code: "EN", prefix: "/", og_locale: "en_US"},
    pt: %{lang: "pt-BR", gettext: "pt_BR", code: "PT", prefix: "/pt/", og_locale: "pt_BR"}
  }

  @doc "Supported languages, default first."
  def langs, do: [:en, :pt]

  @doc "Site origin, without a trailing slash."
  def base_url, do: @base_url

  @doc "Settings for `lang`."
  def get(lang), do: Map.fetch!(@locales, lang)

  @doc "The other language (target of the EN/PT switch)."
  def other(:en), do: :pt
  def other(:pt), do: :en

  @doc "Site path of `page` (:home | :resume) in `lang`."
  def path(lang, :home), do: get(lang).prefix
  def path(lang, :resume), do: get(lang).prefix <> "resume/"

  @doc "Absolute URL of `page` in `lang`."
  def url(lang, page), do: @base_url <> path(lang, page)

  @doc "Runs `fun` with the Gettext locale of `lang`, returning its result."
  def with_locale(lang, fun), do: Gettext.with_locale(Site.Gettext, get(lang).gettext, fun)
end
