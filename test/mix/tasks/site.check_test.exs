defmodule Mix.Tasks.Site.CheckTest do
  use ExUnit.Case

  alias Mix.Tasks.Site.Check

  @moduletag :tmp_dir

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  end

  describe "run/1" do
    test "reports a clean site", %{tmp_dir: root} do
      Check.run(["--root", root])
      assert_received {:mix_shell, :info, [_message]}
    end

    test "fails on a broken reference", %{tmp_dir: root} do
      File.write!(Path.join(root, "index.html"), ~s(<img src="/missing.png">))
      assert_raise Mix.Error, fn -> Check.run(["--root", root]) end
    end

    test "lists each broken reference", %{tmp_dir: root} do
      File.write!(Path.join(root, "index.html"), ~s(<img src="/missing.png">))
      catch_error(Check.run(["--root", root]))
      assert_received {:mix_shell, :error, ["index.html: /missing.png"]}
    end
  end
end
