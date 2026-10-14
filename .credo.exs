# Credo's default checks, run in strict mode, plus a few opt-in ones.
# List every check with `mix credo list`; explain one with `mix credo explain <check>`.
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/", "mix.exs"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      strict: true,
      checks: %{
        extra: [
          # one alias per line: `alias Site.I18n`, never `alias Site.{I18n, Pages}`
          {Credo.Check.Readability.MultiAlias, []},
          # `a |> f()` with a single pipe reads better as `f(a)`
          {Credo.Check.Readability.SinglePipe, []},
          # @shortdoc/@moduledoc, then use/import/alias/require, in that order
          {Credo.Check.Readability.StrictModuleLayout, []}
        ]
      }
    }
  ]
}
