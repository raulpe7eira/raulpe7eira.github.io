defmodule Site.LiveReload.Watcher do
  @moduledoc """
  Watches the sources while `mix site.server` runs and keeps `docs/` and the
  browser up to date:

    * a change in `data/`, `lib/` or `priv/` recompiles the project, rebuilds
      the site (with the PDFs unless `pdf: false`) and bumps the version
    * a change in `docs/assets/` (CSS, JS and images are edited there) only
      bumps the version

  Changes within 300 ms are handled once. A compile or build error is
  printed and the last good build keeps being served. The version is read
  by `Site.LiveReload.Plug`, which reloads the open pages when it changes.

  Needs real file events, so it is left out of the coverage report
  (`coveralls.json`).
  """

  use GenServer

  @sources ["data", "lib", "priv"]
  @assets "docs/assets"
  @debounce 300

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "The current build version, as a string."
  def version, do: :persistent_term.get({__MODULE__, :version}, "0")

  @impl GenServer
  def init(opts) do
    bump()
    {:ok, watcher} = FileSystem.start_link(dirs: Enum.map(@sources ++ [@assets], &Path.expand/1))
    FileSystem.subscribe(watcher)
    {:ok, %{pdf: Keyword.get(opts, :pdf, true), pending: nil, timer: nil}}
  end

  @impl GenServer
  def handle_info({:file_event, _watcher, {path, _events}}, state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    kind = if String.starts_with?(path, Path.expand(@assets)), do: :assets, else: :sources
    pending = if :sources in [kind, state.pending], do: :sources, else: :assets
    timer = Process.send_after(self(), :rebuild, @debounce)
    {:noreply, %{state | pending: pending, timer: timer}}
  end

  def handle_info({:file_event, _watcher, :stop}, state), do: {:noreply, state}

  def handle_info(:rebuild, %{pending: :assets} = state) do
    bump()
    Mix.shell().info("assets changed, reloading")
    {:noreply, %{state | pending: nil, timer: nil}}
  end

  def handle_info(:rebuild, %{pending: :sources} = state) do
    rebuild(state.pdf)
    {:noreply, %{state | pending: nil, timer: nil}}
  end

  defp rebuild(pdf) do
    started = System.monotonic_time(:millisecond)
    Mix.Task.reenable("compile.elixir")

    case Mix.Task.run("compile.elixir", ["--return-errors"]) do
      {:error, _diagnostics} ->
        Mix.shell().error("compile failed, still serving the last build")

      _compiled ->
        build(pdf, started)
    end
  end

  defp build(pdf, started) do
    Site.build("docs", pdf: pdf)
    bump()
    Mix.shell().info("rebuilt in #{System.monotonic_time(:millisecond) - started} ms, reloading")
  rescue
    error ->
      Mix.shell().error(
        "build failed, still serving the last build: " <> Exception.message(error)
      )
  end

  defp bump do
    :persistent_term.put({__MODULE__, :version}, Integer.to_string(System.os_time(:millisecond)))
  end
end
