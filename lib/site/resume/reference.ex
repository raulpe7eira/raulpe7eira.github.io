defmodule Site.Resume.Reference do
  @moduledoc "A client or project listed in a role (its logo is derived from the name)."

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  @primary_key false
  embedded_schema do
    field :name, :string
    field :url, :string
    field :acquired_by, :string
  end

  @doc false
  def changeset(reference, attrs) do
    reference
    |> cast(attrs, [:name, :url, :acquired_by])
    |> validate_required([:name])
    |> validate_url(:url)
  end
end
