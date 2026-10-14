defmodule Site.Resume.ProfileTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Profile

  @valid %{
    "name" => "Raul Pereira da Silva",
    "summary" => %{"en_us" => "Backend engineer.", "pt_br" => "Engenheiro backend."},
    "location" => %{"en_us" => "Rio de Janeiro, Brazil", "pt_br" => "Rio de Janeiro, Brasil"},
    "email" => "raul.pereira@gmail.com",
    "website" => "https://raulpe7eira.tech",
    "linkedin" => "https://linkedin.com/in/raulpe7eira",
    "github" => "https://github.com/raulpe7eira"
  }

  describe "changeset/2" do
    test "accepts a complete profile" do
      assert changeset(@valid).valid?
    end

    test "requires a summary" do
      assert %{summary: ["can't be blank"]} = errors(Map.delete(@valid, "summary"))
    end

    test "rejects an invalid email" do
      assert %{email: ["has invalid format"]} = errors(Map.put(@valid, "email", "raul"))
    end

    test "rejects a website that is not https" do
      assert %{website: ["must be an https URL"]} =
               errors(Map.put(@valid, "website", "http://raulpe7eira.tech"))
    end
  end

  defp changeset(attrs), do: Profile.changeset(%Profile{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
