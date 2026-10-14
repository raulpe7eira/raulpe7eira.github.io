defmodule Site.Resume.Profile do
  @moduledoc "Header of the resume: name, summary, location and public contacts."

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  alias Site.Resume.Translated

  @primary_key false
  embedded_schema do
    field :name, :string
    embeds_one :summary, Translated
    embeds_one :location, Translated
    field :email, :string
    field :website, :string
    field :linkedin, :string
    field :github, :string
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:name, :email, :website, :linkedin, :github])
    |> cast_embed(:summary, required: true)
    |> cast_embed(:location, required: true)
    |> validate_required([:name, :email, :website, :linkedin, :github])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+$/)
    |> validate_url(:website)
    |> validate_url(:linkedin)
    |> validate_url(:github)
  end
end
