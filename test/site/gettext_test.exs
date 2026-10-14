defmodule Site.GettextTest do
  use ExUnit.Case, async: true

  # msgids are keys (e.g. "footer.made_with"), so every locale needs the text,
  # English included; a missing entry would render the raw key.

  describe "en translations" do
    test "every key has English text" do
      assert untranslated("en") == []
    end
  end

  describe "pt_BR translations" do
    test "every key has Portuguese text" do
      assert untranslated("pt_BR") == []
    end
  end

  describe "known locales" do
    test "has English and Brazilian Portuguese" do
      assert Enum.sort(Gettext.known_locales(Site.Gettext)) == ["en", "pt_BR"]
    end
  end

  defp untranslated(locale) do
    Expo.PO.parse_file!("priv/gettext/#{locale}/LC_MESSAGES/default.po").messages
    |> Enum.filter(&(&1.msgstr |> IO.iodata_to_binary() |> String.trim() == ""))
    |> Enum.map(&IO.iodata_to_binary(&1.msgid))
  end
end
