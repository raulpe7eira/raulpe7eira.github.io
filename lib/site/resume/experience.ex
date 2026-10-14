defmodule Site.Resume.Experience do
  @moduledoc """
  A company and the roles held there, newest first (as on LinkedIn).

  `company` keeps the LinkedIn name; `Site.Resume.display_name/1` shortens it for display.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Site.Resume.Validations

  alias Site.Resume.Role

  @primary_key false
  embedded_schema do
    field :company, :string
    field :url, :string
    field :acquired_by, :string
    embeds_many :roles, Role
  end

  @doc false
  def changeset(experience, attrs) do
    experience
    |> cast(attrs, [:company, :url, :acquired_by])
    |> cast_embed(:roles, required: true)
    |> validate_required([:company, :url])
    |> validate_url(:url)
    |> validate_roles_timeline()
  end

  # Roles are newest first: only the first may be open, and each must end
  # no later than the next (newer) one starts.
  defp validate_roles_timeline(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp validate_roles_timeline(changeset) do
    changeset
    |> get_field(:roles)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(changeset, fn [newer, older], acc ->
      cond do
        is_nil(older.finished_on) ->
          add_error(acc, :roles, "only the most recent role can be open")

        Date.compare(older.finished_on, newer.started_on) == :gt ->
          add_error(acc, :roles, "roles overlap")

        true ->
          acc
      end
    end)
  end
end
