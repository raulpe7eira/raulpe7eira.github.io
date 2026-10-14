defmodule Site.Templates do
  @moduledoc "EEx templates from priv/templates, compiled into functions that take `assigns`."

  require EEx

  @dir Path.expand("../../priv/templates", __DIR__)

  # {function, file, args}: templates that don't read assigns take `_assigns`
  @templates [
    {:layout, "layout.html.eex", [:assigns]},
    {:home_en, "home/en.html.eex", [:_assigns]},
    {:home_pt, "home/pt.html.eex", [:_assigns]},
    {:social, "partials/social.html.eex", [:_assigns]},
    {:jsonld_home, "partials/jsonld_home.html.eex", [:assigns]}
  ]

  for {name, file, args} <- @templates do
    path = Path.join(@dir, file)
    @external_resource path
    EEx.function_from_file(:def, name, path, args)
  end
end
