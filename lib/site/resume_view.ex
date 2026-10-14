defmodule Site.ResumeView do
  @moduledoc """
  Turns `%Site.Resume{}` into plain maps the resume templates print, in one
  language: picks the translations, formats dates and derives logo names.

  Text is not escaped here (templates do it). Labels come from Gettext, so
  call `build/2` inside `Site.Locale.with_locale/2`.
  """

  alias Site.Labels
  alias Site.Resume

  # In the PDF, companies whose last role ended up to this year are condensed
  # under "Earlier experience" to keep it at two pages.
  @earlier_until 2012

  @doc "The resume in `lang` (`:en_us` or `:pt_br`), ready for the templates."
  def build(%Resume{} = resume, lang) do
    profile = resume.profile

    %{
      name: profile.name,
      summary: String.split(translate(profile.summary, lang), "\n\n"),
      location: translate(profile.location, lang),
      email: profile.email,
      website: link(profile.website),
      linkedin: link(profile.linkedin),
      github: link(profile.github),
      experiences: Enum.map(resume.experiences, &experience(&1, lang)),
      educations: Enum.map(resume.educations, &education(&1, lang)),
      skills: Enum.map(resume.skills, &skill/1),
      languages: Enum.map(resume.languages, &language(&1, lang))
    }
  end

  @doc ~S|Logo file name for a company or client, e.g. "Meu Patrocínio" -> "meu-patrocinio".|
  def slug(name) do
    name
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp experience(experience, lang) do
    [latest | _older] = roles = experience.roles
    name = Resume.display_name(experience.company)

    %{
      name: name,
      url: experience.url,
      logo: "sq-" <> slug(name),
      acquired_by: experience.acquired_by,
      location: place(latest, lang),
      period: period(List.last(roles).started_on, latest.finished_on),
      earlier?: earlier?(latest.finished_on),
      roles: Enum.map(roles, &role(&1, lang))
    }
  end

  defp role(role, lang) do
    {paragraphs, bullets} = description(translate(role.description, lang))

    %{
      title: translate(role.title, lang),
      period: period(role.started_on, role.finished_on),
      location: place(role, lang),
      paragraphs: paragraphs,
      bullets: bullets,
      references: references(role),
      stack: role.stack
    }
  end

  # Paragraphs are separated by a blank line; bullet lines start with "- ".
  defp description(text) do
    {lists, paragraphs} =
      text
      |> String.split("\n\n")
      |> Enum.split_with(&String.starts_with?(&1, "- "))

    bullets =
      lists
      |> Enum.flat_map(&String.split(&1, "\n"))
      |> Enum.map(&String.replace_prefix(&1, "- ", ""))

    {paragraphs, bullets}
  end

  defp references(role) do
    for {group, references} <- [clients: role.clients, projects: role.projects],
        references != [] do
      %{label: Labels.reference_group(group), items: Enum.map(references, &reference/1)}
    end
  end

  defp reference(reference) do
    %{
      name: reference.name,
      url: reference.url,
      logo: "cl-" <> slug(reference.name),
      acquired_by: reference.acquired_by
    }
  end

  defp education(education, lang) do
    %{
      name: Resume.display_name(education.school),
      school: education.school,
      url: education.url,
      closed_in: education.closed_in,
      degree:
        translate(education.degree, lang) <> ", " <> translate(education.field_of_study, lang),
      period: period(education.started_on, education.finished_on)
    }
  end

  defp skill(skill), do: %{label: Labels.skill(skill.type), items: skill.items}

  defp language(language, lang),
    do: "#{translate(language.name, lang)} (#{Labels.proficiency(language.proficiency)})"

  defp place(role, lang) do
    location = role.location && translate(role.location, lang)

    [location, Labels.work_mode(role.work_mode)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp period(started_on, nil), do: Labels.month_year(started_on) <> " - " <> Labels.present()

  defp period(started_on, finished_on),
    do: Labels.month_year(started_on) <> " - " <> Labels.month_year(finished_on)

  defp earlier?(nil), do: false
  defp earlier?(finished_on), do: finished_on.year <= @earlier_until

  defp link(url), do: %{url: url, label: String.replace_prefix(url, "https://", "")}

  defp translate(translated, lang), do: Map.fetch!(translated, lang)
end
