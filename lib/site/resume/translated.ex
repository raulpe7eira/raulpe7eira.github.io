defmodule Site.Resume.Translated do
  @moduledoc "Text that comes from LinkedIn in both languages."

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :en_us, :string
    field :pt_br, :string
  end

  @doc false
  def changeset(translated, attrs) do
    translated
    |> cast(attrs, [:en_us, :pt_br])
    |> validate_required([:en_us, :pt_br])
  end
end
