defmodule Site.I18n do
  @moduledoc "Per-language strings shared by every page."

  @base_url "https://raulpe7eira.tech"

  @strings %{
    en: %{
      lang: "en",
      lang_code: "EN",
      prefix: "/",
      og_locale: "en_US",
      job_title: "Software Engineer",
      resume_label: "Resume",
      switch_label: "View in English",
      avatar_alt: "Photo of Raul Pereira (raulpe7eira)",
      subtitle: "Passionate coder, and cycling enthusiast,<br />who loves being with the family",
      made_with: "Made with",
      by: "by",
      home_description:
        "Software engineer with 20+ years of experience, focused on Elixir and AI. Cycling enthusiast who loves being with the family."
    },
    pt: %{
      lang: "pt-BR",
      lang_code: "PT",
      prefix: "/pt/",
      og_locale: "pt_BR",
      job_title: "Engenheiro de Software",
      resume_label: "Currículo",
      switch_label: "Ver em português",
      avatar_alt: "Foto de Raul Pereira (raulpe7eira)",
      subtitle: "Programador apaixonado, e ciclista entusiasta,<br />que ama estar com a família",
      made_with: "Feito com",
      by: "por",
      home_description:
        "Engenheiro de software com mais de 20 anos de experiência, focado em Elixir e IA. Ciclista entusiasta que ama estar com a família."
    }
  }

  @doc "Supported languages, default first."
  def langs, do: [:en, :pt]

  @doc "Site origin, without a trailing slash."
  def base_url, do: @base_url

  @doc "All strings for `lang`."
  def get(lang), do: Map.fetch!(@strings, lang)

  @doc "The other language (target of the EN/PT switch)."
  def other(:en), do: :pt
  def other(:pt), do: :en

  @doc "Site path of `page` (:home | :resume) in `lang`."
  def path(lang, :home), do: get(lang).prefix
  def path(lang, :resume), do: get(lang).prefix <> "resume/"

  @doc "Absolute URL of `page` in `lang`."
  def url(lang, page), do: @base_url <> path(lang, page)
end
