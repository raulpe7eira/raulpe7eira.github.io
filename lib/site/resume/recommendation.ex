defmodule Site.Resume.Recommendation do
  @moduledoc """
  A recommendation received on LinkedIn, kept in its original language.

  `relationship` is how LinkedIn describes it (its label comes from Gettext).
  `headline` is the recommender's current one, as LinkedIn shows it.
  `worked_together_at`, `photo` and `hidden` exist only on the site: where
  the two worked together (LinkedIn doesn't say), whether the recommender's
  photo is in `docs/assets/images/people/` (otherwise their initials show)
  and whether to leave it off the resume page.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  @relationships [:same_team, :different_teams, :senior_colleague, :teacher, :service_provider]

  @primary_key false
  embedded_schema do
    field :name, :string
    field :url, :string
    field :headline, :string
    field :relationship, Ecto.Enum, values: @relationships
    field :given_on, :date
    field :text, :string
    field :worked_together_at, :string
    field :photo, :boolean, default: false
    field :hidden, :boolean, default: false
  end

  @doc false
  def changeset(recommendation, attrs) do
    recommendation
    |> cast(attrs, [
      :name,
      :url,
      :headline,
      :relationship,
      :given_on,
      :text,
      :worked_together_at,
      :photo,
      :hidden
    ])
    |> validate_required([:name, :url, :relationship, :given_on, :text])
    |> validate_url(:url)
  end
end
