defmodule Site.Resume.Highlights do
  @moduledoc """
  A short paragraph on the career, for `llms.txt` (English only, like that file).

  LinkedIn has no equivalent field: when the experiences change, a new text
  is suggested (e.g. by the LinkedIn reading skill) and reviewed in the diff.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :en_us, :string
  end

  @doc false
  def changeset(highlights, attrs) do
    highlights
    |> cast(attrs, [:en_us])
    |> validate_required([:en_us])
  end
end
