defmodule Site.Resume.Skill do
  @moduledoc """
  A group of skills. `type` is one of the known groups, whose labels come
  from Gettext (`Site.Labels.skill/1`); items stay as on LinkedIn, untranslated.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  @types [:ai, :ai_coding, :programming, :frameworks, :data, :observability, :practices]

  @primary_key false
  embedded_schema do
    field :type, Ecto.Enum, values: @types
    field :items, {:array, :string}
  end

  @doc false
  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:type, :items])
    |> validate_required([:type, :items])
    |> validate_length(:items, min: 1)
    |> validate_unique_items(:items)
  end
end
