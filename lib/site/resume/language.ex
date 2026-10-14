defmodule Site.Resume.Language do
  @moduledoc "A spoken language. Proficiency levels are LinkedIn's; their labels come from Gettext."

  use Ecto.Schema

  import Ecto.Changeset

  alias Site.Resume.Translated

  @proficiencies [
    :elementary,
    :limited_working,
    :professional_working,
    :full_professional,
    :native_or_bilingual
  ]

  @primary_key false
  embedded_schema do
    embeds_one :name, Translated
    field :proficiency, Ecto.Enum, values: @proficiencies
  end

  @doc false
  def changeset(language, attrs) do
    language
    |> cast(attrs, [:proficiency])
    |> cast_embed(:name, required: true)
    |> validate_required([:proficiency])
  end
end
