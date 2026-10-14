defmodule Site.Resume.Validations do
  @moduledoc "Changeset validations shared by the resume schemas."

  import Ecto.Changeset

  @doc "Requires `field`, when present, to be an https URL."
  def validate_url(changeset, field) do
    validate_format(changeset, field, ~r{^https://\S+$}, message: "must be an https URL")
  end

  @doc "Requires `to`, when present, not to be before `from`."
  def validate_date_order(changeset, from, to) do
    started = get_field(changeset, from)
    finished = get_field(changeset, to)

    if started && finished && Date.compare(finished, started) == :lt do
      add_error(changeset, to, "must not be before #{from}", validation: :date_order)
    else
      changeset
    end
  end

  @doc "Rejects repeated items in a list field."
  def validate_unique_items(changeset, field) do
    validate_change(changeset, field, fn ^field, items ->
      case Enum.uniq(items -- Enum.uniq(items)) do
        [] -> []
        repeated -> [{field, "has repeated items: #{Enum.join(repeated, ", ")}"}]
      end
    end)
  end
end
