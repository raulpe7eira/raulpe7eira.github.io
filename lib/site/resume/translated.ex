defmodule Site.Resume.Translated do
  @moduledoc "Text that comes from LinkedIn in both languages."

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :en, :string
    field :pt, :string
  end

  @doc false
  def changeset(translated, attrs) do
    translated
    |> cast(attrs, [:en, :pt])
    |> validate_required([:en, :pt])
  end
end
