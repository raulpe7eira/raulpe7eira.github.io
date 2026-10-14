defmodule Site.Resume.ExperienceTest do
  use ExUnit.Case, async: true

  alias Site.Resume.Experience

  describe "changeset/2" do
    test "accepts roles in order without gaps" do
      assert changeset([role("2021-05-01", nil), role("2019-02-01", "2021-04-01")]).valid?
    end

    test "accepts a role that starts in the month the previous one ended" do
      assert changeset([role("2019-02-01", nil), role("2018-02-01", "2019-02-01")]).valid?
    end

    test "rejects overlapping roles" do
      assert %{roles: ["roles overlap"]} =
               errors([role("2019-02-01", nil), role("2018-02-01", "2019-06-01")])
    end

    test "rejects an open role that is not the most recent" do
      assert %{roles: ["only the most recent role can be open"]} =
               errors([role("2021-05-01", "2022-07-01"), role("2019-02-01", nil)])
    end

    test "requires at least one role" do
      assert %{roles: ["can't be blank"]} = errors([])
    end
  end

  defp changeset(roles) do
    Experience.changeset(%Experience{}, %{
      "company" => "Jaya Tech",
      "url" => "https://jaya.tech",
      "roles" => roles
    })
  end

  defp errors(roles), do: roles |> changeset() |> Ecto.Changeset.traverse_errors(&elem(&1, 0))

  defp role(started_on, finished_on) do
    %{
      "title" => %{"en_us" => "Role", "pt_br" => "Cargo"},
      "started_on" => started_on,
      "finished_on" => finished_on,
      "description" => %{"en_us" => "Did things.", "pt_br" => "Fiz coisas."}
    }
  end
end
