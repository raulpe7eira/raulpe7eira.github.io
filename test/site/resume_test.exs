defmodule Site.ResumeTest do
  use ExUnit.Case, async: true

  alias Site.Resume

  @moduletag :tmp_dir

  describe "load/1" do
    test "loads the real data in data/" do
      assert {:ok, %Resume{}} = Resume.load("data")
    end

    test "returns every experience" do
      {:ok, resume} = Resume.load("data")
      assert length(resume.experiences) == 14
    end

    test "points to the file, item and field of an invalid entry", %{tmp_dir: dir} do
      copy_data(dir)
      write(dir, "skills.json", [%{"type" => "ai", "items" => []}])

      assert {:error, [{"skills.json[0]", %{items: [_ | _]}}]} = Resume.load(dir)
    end

    test "reports errors from more than one file", %{tmp_dir: dir} do
      copy_data(dir)
      write(dir, "skills.json", [%{"type" => "ai", "items" => []}])

      write(dir, "languages.json", [
        %{"name" => %{"en_us" => "German"}, "proficiency" => "native"}
      ])

      assert {:error, errors} = Resume.load(dir)

      assert errors |> Enum.map(&elem(&1, 0)) |> Enum.sort() == [
               "languages.json[0]",
               "skills.json[0]"
             ]
    end
  end

  describe "load!/1" do
    test "returns the resume when the data is valid" do
      assert %Resume{} = Resume.load!("data")
    end

    test "raises with the errors when the data is invalid", %{tmp_dir: dir} do
      copy_data(dir)
      write(dir, "skills.json", [%{"type" => "ai", "items" => []}])

      assert_raise ArgumentError, ~r/skills\.json\[0\]/, fn -> Resume.load!(dir) end
    end
  end

  describe "display_name/1" do
    test "shortens a listed company" do
      assert Resume.display_name("BRQ IT Services") == "BRQ"
    end

    test "shortens a listed school" do
      assert Resume.display_name("Pontifícia Universidade Católica do Rio de Janeiro") ==
               "PUC-Rio"
    end

    test "keeps any other name as is" do
      assert Resume.display_name("Arionkoder") == "Arionkoder"
    end
  end

  defp copy_data(dir), do: File.cp_r!("data", dir)

  defp write(dir, file, data), do: File.write!(Path.join(dir, file), JSON.encode!(data))
end
