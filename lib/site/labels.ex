defmodule Site.Labels do
  @moduledoc """
  Labels for values that come from the resume data (dates, work modes,
  skill types, proficiencies), in the current Gettext locale.

  One clause per value, so `mix gettext.extract` finds every key.
  """

  use Gettext, backend: Site.Gettext

  @doc ~S|Month and year, e.g. "Oct 2025" (or "Out 2025" in Portuguese).|
  def month_year(%Date{month: month, year: year}), do: "#{month(month)} #{year}"

  @doc "Shown instead of the end date of an open role."
  def present, do: gettext("date.present")

  @doc "Label of a role's work mode; `nil` when there is none."
  def work_mode(:remote), do: gettext("work_mode.remote")
  def work_mode(:hybrid), do: gettext("work_mode.hybrid")
  def work_mode(:on_site), do: gettext("work_mode.on_site")
  def work_mode(nil), do: nil

  @doc "Label of a skill group."
  def skill(:ai), do: gettext("skills.ai")
  def skill(:ai_coding), do: gettext("skills.ai_coding")
  def skill(:programming), do: gettext("skills.programming")
  def skill(:frameworks), do: gettext("skills.frameworks")
  def skill(:data), do: gettext("skills.data")
  def skill(:observability), do: gettext("skills.observability")
  def skill(:practices), do: gettext("skills.practices")

  @doc "Short label of a language proficiency, e.g. \"native\"."
  def proficiency(:elementary), do: gettext("proficiency.elementary")
  def proficiency(:limited_working), do: gettext("proficiency.limited_working")
  def proficiency(:professional_working), do: gettext("proficiency.professional_working")
  def proficiency(:full_professional), do: gettext("proficiency.full_professional")
  def proficiency(:native_or_bilingual), do: gettext("proficiency.native_or_bilingual")

  @doc "Label of a group of references in a role."
  def reference_group(:clients), do: gettext("resume.clients")
  def reference_group(:projects), do: gettext("resume.projects")

  defp month(1), do: gettext("date.month.jan")
  defp month(2), do: gettext("date.month.feb")
  defp month(3), do: gettext("date.month.mar")
  defp month(4), do: gettext("date.month.apr")
  defp month(5), do: gettext("date.month.may")
  defp month(6), do: gettext("date.month.jun")
  defp month(7), do: gettext("date.month.jul")
  defp month(8), do: gettext("date.month.aug")
  defp month(9), do: gettext("date.month.sep")
  defp month(10), do: gettext("date.month.oct")
  defp month(11), do: gettext("date.month.nov")
  defp month(12), do: gettext("date.month.dec")
end
