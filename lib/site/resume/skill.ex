defmodule Site.Resume.Skill do
  @moduledoc """
  A group of skills. `type` is a key whose label comes from Gettext
  (`skills.<type>`); items stay as on LinkedIn, untranslated.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  @primary_key false
  embedded_schema do
    field :type, :string
    field :items, {:array, :string}
  end

  @doc false
  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:type, :items])
    |> validate_required([:type, :items])
    |> validate_format(:type, ~r/^[a-z_]+$/)
    |> validate_length(:items, min: 1)
    |> validate_unique_items(:items)
  end
end
