defmodule Site.Resume.RoleTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Role

  @valid %{
    "title" => %{"en" => "Tech Lead", "pt" => "Líder Técnico"},
    "started_on" => "2019-02-01",
    "finished_on" => "2021-04-01",
    "description" => %{"en" => "Led the team.", "pt" => "Liderei o time."},
    "stack" => ["Kotlin", "Java"]
  }

  describe "changeset/2" do
    test "accepts a complete role" do
      assert changeset(@valid).valid?
    end

    test "accepts an open role without finished_on" do
      assert changeset(Map.delete(@valid, "finished_on")).valid?
    end

    test "requires a title" do
      assert %{title: ["can't be blank"]} = errors(Map.delete(@valid, "title"))
    end

    test "requires a description" do
      assert %{description: ["can't be blank"]} = errors(Map.delete(@valid, "description"))
    end

    test "rejects finishing before starting" do
      assert %{finished_on: ["must not be before started_on"]} =
               errors(Map.put(@valid, "finished_on", "2018-01-01"))
    end

    test "rejects repeated stack items" do
      assert %{stack: ["has repeated items: Java"]} =
               errors(Map.put(@valid, "stack", ["Java", "Kotlin", "Java"]))
    end

    test "rejects an unknown work mode" do
      assert %{work_mode: ["is invalid"]} = errors(Map.put(@valid, "work_mode", "office"))
    end

    test "rejects a client url that is not https" do
      clients = [%{"name" => "C6 Bank", "url" => "http://www.c6bank.com.br"}]

      assert %{clients: [%{url: ["must be an https URL"]}]} =
               errors(Map.put(@valid, "clients", clients))
    end
  end

  defp changeset(attrs), do: Role.changeset(%Role{}, attrs)
  defp errors(attrs), do: attrs |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))
end
