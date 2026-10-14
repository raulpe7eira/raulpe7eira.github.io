defmodule Site.Gettext do
  @moduledoc """
  Gettext backend for the site's interface text (labels, titles, alt texts).

  Messages live in `priv/gettext`; English is the source language and
  `pt_BR` holds the translations. Content that comes from LinkedIn in both
  languages is not translated here.
  """
  use Gettext.Backend, otp_app: :site
end
