defmodule Site.Resume.Role do
  @moduledoc "A position held at a company, as on LinkedIn."

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  alias Site.Resume.Reference
  alias Site.Resume.Translated

  @primary_key false
  embedded_schema do
    embeds_one :title, Translated
    field :started_on, :date
    field :finished_on, :date
    embeds_one :location, Translated
    field :work_mode, Ecto.Enum, values: [:remote, :hybrid, :on_site]
    embeds_one :description, Translated
    field :stack, {:array, :string}, default: []
    embeds_many :clients, Reference
    embeds_many :projects, Reference
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:started_on, :finished_on, :work_mode, :stack])
    |> cast_embed(:title, required: true)
    |> cast_embed(:location)
    |> cast_embed(:description, required: true)
    |> cast_embed(:clients)
    |> cast_embed(:projects)
    |> validate_required([:started_on])
    |> validate_date_order(:started_on, :finished_on)
    |> validate_unique_items(:stack)
  end
end
