defmodule Mix.Tasks.Site.BuildTest do
  use ExUnit.Case

  alias Mix.Tasks.Site.Build

  @moduletag :tmp_dir

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  end

  describe "run/1" do
    test "writes the pages to --output", %{tmp_dir: dir} do
      Build.run(["--output", dir])

      assert File.exists?(Path.join(dir, "index.html"))
      assert File.exists?(Path.join(dir, "pt/index.html"))
    end

    test "reports each written file", %{tmp_dir: dir} do
      Build.run(["--output", dir])

      english = Path.join(dir, "index.html")
      portuguese = Path.join(dir, "pt/index.html")
      assert_received {:mix_shell, :info, ["wrote " <> ^english]}
      assert_received {:mix_shell, :info, ["wrote " <> ^portuguese]}
    end

    test "rejects unknown options" do
      assert_raise OptionParser.ParseError, fn -> Build.run(["--out", "x"]) end
    end
  end
end
