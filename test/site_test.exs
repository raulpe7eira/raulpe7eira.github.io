defmodule SiteTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @pages ["index.html", "resume/index.html", "pt/index.html", "pt/resume/index.html"]

  describe "build/2" do
    test "returns the path of every page written", %{tmp_dir: dir} do
      assert Enum.sort(Site.build(dir)) == Enum.sort(Enum.map(@pages, &Path.join(dir, &1)))
    end

    test "writes the files to disk", %{tmp_dir: dir} do
      assert dir |> Site.build() |> Enum.all?(&File.exists?/1)
    end

    test "prints no PDF unless asked", %{tmp_dir: dir} do
      Site.build(dir, pdf: false)

      refute File.exists?(Path.join(dir, "resume/raul-pereira-da-silva-resume.pdf"))
    end
  end
end
