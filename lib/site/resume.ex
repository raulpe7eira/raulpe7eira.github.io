defmodule Site.Resume do
  @moduledoc """
  Resume data, loaded from the JSON files in `data/` and validated by the
  `Site.Resume.*` schemas.

  Pure apart from reading the files: no rendering here, so the same data can
  feed the resume pages, the PDFs or other front ends.
  """

  alias Site.Resume.Education
  alias Site.Resume.Experience
  alias Site.Resume.Highlights
  alias Site.Resume.Language
  alias Site.Resume.Profile
  alias Site.Resume.Skill

  defstruct [:profile, :experiences, :educations, :skills, :languages, :highlights]

  @sources [
    profile: {Profile, :one},
    experiences: {Experience, :many},
    educations: {Education, :many},
    skills: {Skill, :many},
    languages: {Language, :many},
    highlights: {Highlights, :one}
  ]

  # LinkedIn names that read better shortened on the resume; everything else is kept as is.
  @display_names %{
    "BRQ IT Services" => "BRQ",
    "SUPPLY MIDIA - EDI & ERP SOLUTIONS" => "Supply Midia",
    "SONDA" => "Sonda",
    "DRIVE" => "Drive",
    "Pontifícia Universidade Católica do Rio de Janeiro" => "PUC-Rio",
    "Centro Universitário da Cidade" => "UniverCidade"
  }

  @doc """
  Loads and validates every file in `dir`.

  Returns `{:ok, %Site.Resume{}}`, or `{:error, errors}` where each error is
  `{"file.json" | "file.json[index]", errors_by_field}`.
  """
  def load(dir \\ "data") do
    results = for {key, {schema, kind}} <- @sources, do: {key, read(dir, key, schema, kind)}

    case Enum.flat_map(results, fn {_key, result} -> errors(result) end) do
      [] ->
        {:ok, struct(__MODULE__, Enum.map(results, fn {key, {:ok, value}} -> {key, value} end))}

      errors ->
        {:error, errors}
    end
  end

  @doc "Like `load/1`, but raises with every validation error."
  def load!(dir \\ "data") do
    case load(dir) do
      {:ok, resume} -> resume
      {:error, errors} -> raise ArgumentError, "invalid resume data:\n" <> format(errors)
    end
  end

  @doc "Name to show for a company or school: shortened when listed, otherwise unchanged."
  def display_name(name), do: Map.get(@display_names, name, name)

  defp read(dir, key, schema, kind) do
    file = "#{key}.json"
    data = dir |> Path.join(file) |> File.read!() |> JSON.decode!()

    case kind do
      :one ->
        validate(schema, data, file)

      :many ->
        data
        |> Enum.with_index()
        |> Enum.map(fn {item, index} -> validate(schema, item, "#{file}[#{index}]") end)
        |> collect()
    end
  end

  defp validate(schema, attrs, location) do
    schema
    |> struct()
    |> schema.changeset(attrs)
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, value} -> {:ok, value}
      {:error, changeset} -> {:error, [{location, traverse(changeset)}]}
    end
  end

  defp collect(results) do
    case Enum.flat_map(results, &errors/1) do
      [] -> {:ok, Enum.map(results, fn {:ok, value} -> value end)}
      errors -> {:error, errors}
    end
  end

  defp errors({:ok, _value}), do: []
  defp errors({:error, errors}), do: errors

  defp traverse(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r/%{(\w+)}/, message, fn _match, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp format(errors) do
    Enum.map_join(errors, "\n", fn {location, fields} -> "  #{location}: #{inspect(fields)}" end)
  end
end
