defmodule Site.I18nTest do
  use ExUnit.Case, async: true

  alias Site.I18n

  describe "langs/0" do
    test "lists English first, as the default language" do
      assert I18n.langs() == [:en, :pt]
    end
  end

  describe "base_url/0" do
    test "is the site origin without a trailing slash" do
      assert I18n.base_url() == "https://raulpe7eira.tech"
    end
  end

  describe "get/1" do
    test "every language defines the same keys" do
      [first | rest] = Enum.map(I18n.langs(), &(I18n.get(&1) |> Map.keys() |> Enum.sort()))
      assert Enum.all?(rest, &(&1 == first))
    end

    test "raises for an unknown language" do
      assert_raise KeyError, fn -> I18n.get(:es) end
    end
  end

  describe "other/1" do
    test "returns Portuguese for English" do
      assert I18n.other(:en) == :pt
    end

    test "returns English for Portuguese" do
      assert I18n.other(:pt) == :en
    end
  end

  describe "path/2" do
    test "English home is the site root" do
      assert I18n.path(:en, :home) == "/"
    end

    test "Portuguese home is under /pt/" do
      assert I18n.path(:pt, :home) == "/pt/"
    end

    test "English resume is /resume/" do
      assert I18n.path(:en, :resume) == "/resume/"
    end

    test "Portuguese resume is under /pt/" do
      assert I18n.path(:pt, :resume) == "/pt/resume/"
    end
  end

  describe "url/2" do
    test "English home is the base url with a trailing slash" do
      assert I18n.url(:en, :home) == "https://raulpe7eira.tech/"
    end

    test "Portuguese resume joins the base url and its path" do
      assert I18n.url(:pt, :resume) == "https://raulpe7eira.tech/pt/resume/"
    end
  end
end
