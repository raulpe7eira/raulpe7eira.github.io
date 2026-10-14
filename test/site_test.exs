defmodule SiteTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  describe "build/1" do
    test "returns the path of every page written", %{tmp_dir: dir} do
      assert Enum.sort(Site.build(dir)) ==
               Enum.sort([Path.join(dir, "index.html"), Path.join(dir, "pt/index.html")])
    end

    test "writes the files to disk", %{tmp_dir: dir} do
      assert dir |> Site.build() |> Enum.all?(&File.exists?/1)
    end
  end
end
