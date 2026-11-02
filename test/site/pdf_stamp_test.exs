defmodule Site.PdfStampTest do
  use ExUnit.Case, async: true

  alias Site.Pages
  alias Site.PdfStamp
  alias Site.Resume

  @first "sha256:" <> String.duplicate("a", 64)
  @second "sha256:" <> String.duplicate("b", 64)

  setup_all do
    %{resume: Resume.load!()}
  end

  describe "hash/3" do
    @describetag :tmp_dir

    test "does not depend on where the fonts are", %{resume: resume, tmp_dir: dir} do
      first = fonts(Path.join(dir, "one"), "font")
      second = fonts(Path.join(dir, "two"), "font")

      assert PdfStamp.hash(:en_us, resume, first) == PdfStamp.hash(:en_us, resume, second)
    end

    test "changes when a font changes", %{resume: resume, tmp_dir: dir} do
      first = fonts(Path.join(dir, "one"), "font")
      second = fonts(Path.join(dir, "two"), "another font")

      refute PdfStamp.hash(:en_us, resume, first) == PdfStamp.hash(:en_us, resume, second)
    end

    test "changes when the resume data changes", %{resume: resume, tmp_dir: dir} do
      fonts_dir = fonts(dir, "font")
      renamed = put_in(resume.profile.name, "Someone Else")

      refute PdfStamp.hash(:en_us, resume, fonts_dir) == PdfStamp.hash(:en_us, renamed, fonts_dir)
    end

    test "differs between languages", %{resume: resume, tmp_dir: dir} do
      fonts_dir = fonts(dir, "font")

      refute PdfStamp.hash(:en_us, resume, fonts_dir) == PdfStamp.hash(:pt_br, resume, fonts_dir)
    end

    test "is a SHA-256 in hex", %{resume: resume, tmp_dir: dir} do
      assert PdfStamp.hash(:en_us, resume, fonts(dir, "font")) =~ ~r/\Asha256:[0-9a-f]{64}\z/
    end
  end

  describe "stamp/2" do
    test "stores the hash" do
      assert sample_pdf() |> PdfStamp.stamp(@first) |> PdfStamp.read() == @first
    end

    test "keeps the other /Info entries" do
      assert info(PdfStamp.stamp(sample_pdf(), @first)) =~ "/Title (Sample)"
    end

    test "keeps the original PDF as the start of the file" do
      assert String.starts_with?(PdfStamp.stamp(sample_pdf(), @first), sample_pdf())
    end

    test "points the new cross-reference entry to the new /Info object" do
      stamped = PdfStamp.stamp(sample_pdf(), @first)

      assert object_at(stamped, xref_entry(stamped)) =~ ~r/\A1 0 obj\n<<.*SourceHash/s
    end

    test "points startxref to the new cross-reference section" do
      stamped = PdfStamp.stamp(sample_pdf(), @first)

      assert object_at(stamped, startxref(stamped)) =~ ~r/\Axref\n1 1\n/
    end

    test "chains the new trailer to the previous cross-reference" do
      stamped = PdfStamp.stamp(sample_pdf(), @first)

      assert stamped =~ "/Prev #{startxref(sample_pdf())}>>"
    end

    test "replaces the hash when stamped again" do
      assert sample_pdf()
             |> PdfStamp.stamp(@first)
             |> PdfStamp.stamp(@second)
             |> PdfStamp.read() == @second
    end

    test "chains a second stamp to the first one" do
      once = PdfStamp.stamp(sample_pdf(), @first)

      assert PdfStamp.stamp(once, @second) =~ "/Prev #{startxref(once)}>>"
    end
  end

  describe "read/1" do
    test "returns nil for a PDF without a stamp" do
      assert PdfStamp.read(sample_pdf()) == nil
    end
  end

  describe "stale/2" do
    @describetag :tmp_dir

    test "finds no stale PDF when the stamps match", %{resume: resume, tmp_dir: root} do
      write_pdfs(root, resume, fn lang -> PdfStamp.hash(lang, resume, fonts_dir(root)) end)

      assert PdfStamp.stale(root, resume) == []
    end

    test "reports PDFs stamped from other sources", %{resume: resume, tmp_dir: root} do
      write_pdfs(root, resume, fn _lang -> @first end)

      assert PdfStamp.stale(root, resume) == [
               "downloads/raul-pereira-da-silva-resume-en-us.pdf",
               "downloads/raul-pereira-da-silva-resume-pt-br.pdf"
             ]
    end

    test "reports a PDF without a stamp", %{resume: resume, tmp_dir: root} do
      fonts(fonts_dir(root), "font")
      path = Path.join(root, "downloads/raul-pereira-da-silva-resume-en-us.pdf")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, sample_pdf())

      assert PdfStamp.stale(root, resume) == ["downloads/raul-pereira-da-silva-resume-en-us.pdf"]
    end

    test "leaves a missing PDF to the broken link check", %{resume: resume, tmp_dir: root} do
      fonts(fonts_dir(root), "font")

      assert PdfStamp.stale(root, resume) == []
    end
  end

  # a minimal PDF 1.4 like Chrome's: classic cross-reference table and an /Info dictionary
  defp sample_pdf do
    header = "%PDF-1.4\n"

    objects = [
      "1 0 obj\n<</Title (Sample)\n/Producer (Test)>>\nendobj\n",
      "2 0 obj\n<</Type /Catalog /Pages 3 0 R>>\nendobj\n",
      "3 0 obj\n<</Type /Pages /Kids [] /Count 0>>\nendobj\n"
    ]

    {offsets, body_size} =
      Enum.map_reduce(objects, byte_size(header), fn object, offset ->
        {offset, offset + byte_size(object)}
      end)

    entries = Enum.map_join(offsets, &(String.pad_leading("#{&1}", 10, "0") <> " 00000 n \n"))

    header <>
      Enum.join(objects) <>
      "xref\n0 4\n0000000000 65535 f \n" <>
      entries <>
      "trailer\n<</Size 4\n/Root 2 0 R\n/Info 1 0 R>>\nstartxref\n#{body_size}\n%%EOF\n"
  end

  defp info(pdf) do
    ~r{1 0 obj\s*(<<.*?>>)\s*endobj}s
    |> Regex.scan(pdf, capture: :all_but_first)
    |> List.last()
    |> hd()
  end

  defp startxref(pdf) do
    ~r{startxref\s*(\d+)\s*%%EOF}
    |> Regex.scan(pdf, capture: :all_but_first)
    |> List.last()
    |> hd()
    |> String.to_integer()
  end

  defp xref_entry(pdf) do
    [_match, offset] = Regex.run(~r/xref\n1 1\n(\d{10}) 00000 n \n/, pdf)
    String.to_integer(offset)
  end

  defp object_at(pdf, offset), do: binary_part(pdf, offset, byte_size(pdf) - offset)

  defp fonts(dir, content) do
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "inter.woff2"), content)
    dir
  end

  defp fonts_dir(root), do: Path.join(root, "assets/fonts")

  defp write_pdfs(root, resume, hash_for) do
    fonts(fonts_dir(root), "font")

    for lang <- [:en_us, :pt_br] do
      {file, _html} = Pages.resume_pdf(lang, resume, "/fonts")
      path = Path.join(root, file)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, PdfStamp.stamp(sample_pdf(), hash_for.(lang)))
    end
  end
end
