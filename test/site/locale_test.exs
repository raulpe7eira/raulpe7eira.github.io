defmodule Site.LocaleTest do
  use ExUnit.Case, async: true

  use Gettext, backend: Site.Gettext

  alias Site.Locale

  describe "langs/0" do
    test "lists English first, as the default language" do
      assert Locale.langs() == [:en, :pt]
    end
  end

  describe "base_url/0" do
    test "is the site origin without a trailing slash" do
      assert Locale.base_url() == "https://raulpe7eira.tech"
    end
  end

  describe "get/1" do
    test "every language defines the same keys" do
      [first | rest] = Enum.map(Locale.langs(), &(Locale.get(&1) |> Map.keys() |> Enum.sort()))
      assert Enum.all?(rest, &(&1 == first))
    end

    test "raises for an unknown language" do
      assert_raise KeyError, fn -> Locale.get(:es) end
    end
  end

  describe "other/1" do
    test "returns Portuguese for English" do
      assert Locale.other(:en) == :pt
    end

    test "returns English for Portuguese" do
      assert Locale.other(:pt) == :en
    end
  end

  describe "path/2" do
    test "English home is the site root" do
      assert Locale.path(:en, :home) == "/"
    end

    test "Portuguese home is under /pt/" do
      assert Locale.path(:pt, :home) == "/pt/"
    end

    test "English resume is /resume/" do
      assert Locale.path(:en, :resume) == "/resume/"
    end

    test "Portuguese resume is under /pt/" do
      assert Locale.path(:pt, :resume) == "/pt/resume/"
    end
  end

  describe "url/2" do
    test "English home is the base url with a trailing slash" do
      assert Locale.url(:en, :home) == "https://raulpe7eira.tech/"
    end

    test "Portuguese resume joins the base url and its path" do
      assert Locale.url(:pt, :resume) == "https://raulpe7eira.tech/pt/resume/"
    end
  end

  describe "with_locale/2" do
    test "translates into Portuguese" do
      assert Locale.with_locale(:pt, fn -> gettext("toolbar.resume") end) == "Currículo"
    end

    test "translates into English" do
      assert Locale.with_locale(:en, fn -> gettext("toolbar.resume") end) == "Resume"
    end

    test "restores the previous locale afterwards" do
      before = Gettext.get_locale(Site.Gettext)
      Locale.with_locale(:pt, fn -> :ok end)
      assert Gettext.get_locale(Site.Gettext) == before
    end
  end
end
