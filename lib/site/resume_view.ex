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
      timeline: timeline(resume.experiences),
      educations: Enum.map(resume.educations, &education(&1, lang)),
      skills: Enum.map(resume.skills, &skill/1),
      languages: Enum.map(resume.languages, &language(&1, lang)),
      recommendations: recommendations(resume.recommendations),
      all_recommendations_url: profile.linkedin <> "/details/recommendations/"
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
      id: experience_id(experience),
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

  # Anchor of a company on the page, e.g. "xp-brq-2012" (BRQ appears twice)
  defp experience_id(experience) do
    "xp-" <>
      slug(Resume.display_name(experience.company)) <>
      "-" <> to_string(started_on(experience).year)
  end

  defp started_on(experience), do: List.last(experience.roles).started_on
  defp finished_on(experience), do: hd(experience.roles).finished_on

  # The career bar under "Experience": one link per company on a scale from
  # January of the first year to the month after the last date in the data
  # (not today, so rebuilding changes nothing); open roles run to its end.
  # A company that overlaps more than one other (R3M Tech, freelance next to
  # the jobs) goes on a thin lane above the rest. Positions are percentages.
  defp timeline(experiences) do
    dates =
      experiences
      |> Enum.flat_map(fn experience ->
        Enum.flat_map(experience.roles, &[&1.started_on, &1.finished_on])
      end)
      |> Enum.reject(&is_nil/1)

    from = Date.new!(Enum.min(dates, Date).year, 1, 1)
    to = Date.shift(Enum.max(dates, Date), month: 1)

    at = fn date ->
      Float.round(months_between(from, date) * 100 / months_between(from, to), 2)
    end

    # {company, first month, last month}; an open one lasts to the end of the scale
    spans = Enum.map(experiences, &{&1, started_on(&1), finished_on(&1) || to})

    companies =
      spans
      |> Enum.with_index()
      |> Enum.map(fn {{experience, started_on, last} = span, index} ->
        # bars run to the end of their last month (an open one is already there)
        stop = if last == to, do: to, else: Date.shift(last, month: 1)

        %{
          id: experience_id(experience),
          name: Resume.display_name(experience.company),
          period: period(started_on, finished_on(experience)),
          x: at.(started_on),
          width: Float.round(at.(stop) - at.(started_on), 2),
          color: rem(index, 6),
          parallel: Enum.count(spans, &overlap?(&1, span)) > 1
        }
      end)

    years =
      for year <- from.year..to.year, rem(year, 10) == 0 do
        %{
          label: to_string(year),
          x: at.(Date.new!(year, 1, 1)),
          anchor: if(year == from.year, do: "start", else: "middle")
        }
      end

    %{
      companies: companies,
      ticks: years ++ [%{label: Labels.timeline_end(), x: 100.0, anchor: "end"}]
    }
  end

  defp overlap?({same, _started, _stop}, {same, _started_again, _stop_again}), do: false

  # sharing a month is a handoff (LinkedIn has month precision), not an overlap
  defp overlap?({_one, started, last}, {_other, other_started, other_last}),
    do: Date.before?(started, other_last) and Date.before?(other_started, last)

  defp months_between(from, to), do: (to.year - from.year) * 12 + to.month - from.month

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

  # Hidden ones stay in the data (it mirrors LinkedIn) but not on the page.
  defp recommendations(recommendations) do
    for recommendation <- recommendations, not recommendation.hidden do
      recommendation(recommendation)
    end
  end

  # Kept in the language it was written in; only the labels are translated.
  defp recommendation(recommendation) do
    %{
      name: recommendation.name,
      url: recommendation.url,
      headline: recommendation.headline,
      photo: recommendation.photo && "/assets/images/people/#{slug(recommendation.name)}.jpg",
      initials: initials(recommendation.name),
      highlight: recommendation.highlight,
      omitted: omitted(recommendation.text, recommendation.highlight),
      paragraphs: String.split(recommendation.text, "\n\n"),
      context:
        [
          Labels.relationship(recommendation.relationship),
          recommendation.worked_together_at,
          Labels.month_year(recommendation.given_on)
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" · ")
    }
  end

  # Which sides of the highlight leave text out (shown as "…" there), e.g.
  # %{before: true, after: false} when it is the last sentence.
  defp omitted(_text, nil), do: %{before: false, after: false}

  defp omitted(text, highlight) do
    [before, rest] = String.split(text, highlight, parts: 2)
    %{before: String.trim(before) != "", after: String.trim(rest) != ""}
  end

  # First letters of the first and last names, e.g. "Gerson Scanapieco" -> "GS".
  defp initials(name) do
    names = String.split(name)

    [List.first(names), List.last(names)]
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end

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
