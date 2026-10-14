defmodule Site.LocaleTest do
  use ExUnit.Case, async: true

  use Gettext, backend: Site.Gettext

  alias Site.Locale

  describe "langs/0" do
    test "lists English first, as the default language" do
      assert Locale.langs() == [:en_us, :pt_br]
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
      assert Locale.other(:en_us) == :pt_br
    end

    test "returns English for Portuguese" do
      assert Locale.other(:pt_br) == :en_us
    end
  end

  describe "path/2" do
    test "English home is the site root" do
      assert Locale.path(:en_us, :home) == "/"
    end

    test "Portuguese home is under /pt/" do
      assert Locale.path(:pt_br, :home) == "/pt/"
    end

    test "English resume is /resume/" do
      assert Locale.path(:en_us, :resume) == "/resume/"
    end

    test "Portuguese resume is under /pt/" do
      assert Locale.path(:pt_br, :resume) == "/pt/resume/"
    end
  end

  describe "url/2" do
    test "English home is the base url with a trailing slash" do
      assert Locale.url(:en_us, :home) == "https://raulpe7eira.tech/"
    end

    test "Portuguese resume joins the base url and its path" do
      assert Locale.url(:pt_br, :resume) == "https://raulpe7eira.tech/pt/resume/"
    end
  end

  describe "pdf_path/1" do
    test "English PDF is under /downloads/ with its locale" do
      assert Locale.pdf_path(:en_us) == "/downloads/raul-pereira-da-silva-resume-en-us.pdf"
    end

    test "Portuguese PDF is under /downloads/ with its locale" do
      assert Locale.pdf_path(:pt_br) == "/downloads/raul-pereira-da-silva-resume-pt-br.pdf"
    end
  end

  describe "pdf_download_name/1" do
    test "English PDF downloads as the resume" do
      assert Locale.pdf_download_name(:en_us) == "raul-pereira-da-silva-resume.pdf"
    end

    test "Portuguese PDF downloads as the curriculo" do
      assert Locale.pdf_download_name(:pt_br) == "raul-pereira-da-silva-curriculo.pdf"
    end
  end

  describe "with_locale/2" do
    test "translates into Portuguese" do
      assert Locale.with_locale(:pt_br, fn -> gettext("toolbar.resume") end) == "Currículo"
    end

    test "translates into English" do
      assert Locale.with_locale(:en_us, fn -> gettext("toolbar.resume") end) == "Resume"
    end

    test "restores the previous locale afterwards" do
      before = Gettext.get_locale(Site.Gettext)
      Locale.with_locale(:pt_br, fn -> :ok end)
      assert Gettext.get_locale(Site.Gettext) == before
    end
  end
end
