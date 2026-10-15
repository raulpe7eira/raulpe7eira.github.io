defmodule Mix.Tasks.Site.Screenshots do
  @shortdoc "Captures the web manifest screenshots of the home page"
  @moduledoc """
  Captures the phone and desktop screenshots of the home page listed in the
  web manifest (see `Site.Screenshots`). Run it after `mix site.build` when
  the home page looks different.

      mix site.screenshots
  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    for path <- Site.Screenshots.build() do
      Mix.shell().info("wrote #{path}")
    end
  end
end
