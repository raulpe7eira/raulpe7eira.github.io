defmodule Site.Resume.Education do
  @moduledoc "A degree, as on LinkedIn. `closed_in` marks schools that no longer exist."

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  alias Site.Resume.Translated

  @primary_key false
  embedded_schema do
    field :school, :string
    field :url, :string
    field :closed_in, :integer
    embeds_one :degree, Translated
    embeds_one :field_of_study, Translated
    field :started_on, :date
    field :finished_on, :date
  end

  @doc false
  def changeset(education, attrs) do
    education
    |> cast(attrs, [:school, :url, :closed_in, :started_on, :finished_on])
    |> cast_embed(:degree, required: true)
    |> cast_embed(:field_of_study, required: true)
    |> validate_required([:school, :url, :started_on, :finished_on])
    |> validate_url(:url)
    |> validate_number(:closed_in, greater_than: 1900)
    |> validate_date_order(:started_on, :finished_on)
  end
end
