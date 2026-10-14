defmodule Site.Templates do
  @moduledoc """
  EEx templates from priv/templates, compiled into functions that take `assigns`.

  Templates can call `gettext/1,2` (interface labels) and `escape/1` (data text).
  """

  use Gettext, backend: Site.Gettext

  import Site.Html, only: [escape: 1]

  require EEx

  @dir Path.expand("../../priv/templates", __DIR__)

  # {function, file, args}: templates that don't read assigns take `_assigns`
  @templates [
    {:layout, "layout.html.eex", [:assigns]},
    {:home_en_us, "home/en-us.html.eex", [:_assigns]},
    {:home_pt_br, "home/pt-br.html.eex", [:_assigns]},
    {:resume, "resume/page.html.eex", [:assigns]},
    {:resume_pdf, "resume/pdf.html.eex", [:assigns]},
    {:social, "partials/social.html.eex", [:_assigns]},
    {:jsonld_home, "partials/jsonld_home.html.eex", [:assigns]},
    {:jsonld_resume, "partials/jsonld_resume.html.eex", [:assigns]},
    {:sitemap, "sitemap.xml.eex", [:assigns]},
    {:llms, "llms.txt.eex", [:assigns]},
    {:not_found, "404.html.eex", [:assigns]}
  ]

  for {name, file, args} <- @templates do
    path = Path.join(@dir, file)
    @external_resource path
    EEx.function_from_file(:def, name, path, args)
  end

  # PDF: a role's clients, projects and stack as "Label: a, b" notes; when
  # there are exactly two they share one line to save space.
  defp pdf_notes(role) do
    references = for group <- role.references, do: note(group.label, group.items, & &1.name)
    stack = if role.stack == [], do: [], else: [note(gettext("resume.stack"), role.stack, & &1)]

    case references ++ stack do
      [first, second] -> [first <> " &nbsp;·&nbsp; " <> second]
      notes -> notes
    end
  end

  defp note(label, items, name),
    do: "<i>#{escape(label)}:</i> " <> Enum.map_join(items, ", ", &escape(name.(&1)))
end
