defmodule Mix.Tasks.Site.BuildTest do
  use ExUnit.Case

  alias Mix.Tasks.Site.Build

  @moduletag :tmp_dir

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  end

  # The PDFs need Chrome, so these runs use --no-pdf (as CI does).
  describe "run/1" do
    test "writes the pages to --output", %{tmp_dir: dir} do
      Build.run(["--output", dir, "--no-pdf"])

      assert File.exists?(Path.join(dir, "index.html"))
      assert File.exists?(Path.join(dir, "pt/resume/index.html"))
    end

    test "reports each written file", %{tmp_dir: dir} do
      Build.run(["--output", dir, "--no-pdf"])

      english = Path.join(dir, "index.html")
      resume = Path.join(dir, "resume/index.html")
      assert_received {:mix_shell, :info, ["wrote " <> ^english]}
      assert_received {:mix_shell, :info, ["wrote " <> ^resume]}
    end

    test "skips the PDFs with --no-pdf", %{tmp_dir: dir} do
      Build.run(["--output", dir, "--no-pdf"])

      refute File.exists?(Path.join(dir, "resume/raul-pereira-da-silva-resume.pdf"))
    end

    test "rejects unknown options" do
      assert_raise OptionParser.ParseError, fn -> Build.run(["--out", "x"]) end
    end
  end
end
