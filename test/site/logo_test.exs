defmodule Site.LogoTest do
  use ExUnit.Case, async: true

  alias Site.Logo

  @moduletag :tmp_dir

  @white [255, 255, 255]
  @blue [0, 0, 255]
  @transparent [0, 0, 0, 0]

  describe "client_tile/2" do
    test "is 240 wide", %{tmp_dir: dir} do
      assert dir |> tile(@white) |> Image.width() == 240
    end

    test "is 120 high", %{tmp_dir: dir} do
      assert dir |> tile(@white) |> Image.height() == 120
    end

    test "keeps the source background", %{tmp_dir: dir} do
      assert {:ok, [255, 255, 255 | _alpha]} = dir |> tile(@white) |> Image.get_pixel(0, 0)
    end

    test "uses white when the source background is transparent", %{tmp_dir: dir} do
      assert {:ok, [255, 255, 255 | _alpha]} = dir |> tile(@transparent) |> Image.get_pixel(0, 0)
    end

    test "centers the logo", %{tmp_dir: dir} do
      assert {:ok, [0, 0, 0 | _alpha]} = dir |> tile(@white) |> Image.get_pixel(120, 60)
    end

    test "scales the logo to about a fifth of the tile", %{tmp_dir: dir} do
      assert_in_delta dir |> tile(@white) |> logo_area(), 0.20, 0.02
    end

    test "trims transparent margins before scaling", %{tmp_dir: dir} do
      assert_in_delta dir |> tile(@transparent) |> logo_area(), 0.20, 0.02
    end

    test "keeps a source that is only background", %{tmp_dir: dir} do
      source = Path.join(dir, "blank.png")
      400 |> Image.new!(100, color: @white) |> Image.write!(source)

      assert {:ok, [255, 255, 255 | _alpha]} =
               source |> Logo.client_tile() |> Image.get_pixel(120, 60)
    end
  end

  describe "company_tile/2" do
    test "is 400 wide", %{tmp_dir: dir} do
      assert dir |> company(@white) |> Image.width() == 400
    end

    test "is 400 high", %{tmp_dir: dir} do
      assert dir |> company(@white) |> Image.height() == 400
    end

    test "drops the alpha channel", %{tmp_dir: dir} do
      refute dir |> company(@transparent) |> Image.has_alpha?()
    end

    test "keeps the source background", %{tmp_dir: dir} do
      assert {:ok, [0, 0, 255]} = dir |> company(@blue) |> Image.get_pixel(0, 0)
    end

    test "uses white when the source background is transparent", %{tmp_dir: dir} do
      assert {:ok, [255, 255, 255]} = dir |> company(@transparent) |> Image.get_pixel(0, 0)
    end

    test "keeps the framing of a square source", %{tmp_dir: dir} do
      assert_in_delta dir |> company(@white) |> logo_width(), 200, 4
    end

    test "crops a non-square source to its center", %{tmp_dir: dir} do
      assert_in_delta dir |> company(@white, width: 300) |> logo_width(), 200, 4
    end

    test "keeps an off-center logo where it is by default", %{tmp_dir: dir} do
      assert {:ok, [0, 0, 0]} = dir |> company(@white, top: 10) |> Image.get_pixel(200, 60)
    end

    test "recenters an off-center logo with :center", %{tmp_dir: dir} do
      assert {:ok, [255, 255, 255]} =
               dir |> company(@white, top: 10, center: true) |> Image.get_pixel(200, 60)
    end
  end

  describe "client_file/1" do
    test "slugs the name" do
      assert Logo.client_file("Total Bank") == "cl-total-bank.png"
    end
  end

  describe "company_file/1" do
    test "slugs the name" do
      assert Logo.company_file("R3M Tech") == "sq-r3m-tech.png"
    end
  end

  # a 400x100 source with a black 200x50 "logo" in the middle
  defp tile(dir, background) do
    source = Path.join(dir, "logo-#{length(background)}.png")

    400
    |> Image.new!(100, color: background)
    |> Image.compose!(Image.new!(200, 50, color: [0, 0, 0, 255]), x: 100, y: 25)
    |> Image.write!(source)

    Logo.client_tile(source)
  end

  # a 200x200 (or width x 200) source with a black 100x100 "logo", centered
  # unless :top moves it up
  defp company(dir, background, opts \\ []) do
    width = Keyword.get(opts, :width, 200)
    top = Keyword.get(opts, :top, 50)
    source = Path.join(dir, "company-#{length(background)}-#{width}-#{top}.png")

    width
    |> Image.new!(200, color: background)
    |> Image.compose!(Image.new!(100, 100, color: [0, 0, 0, 255]),
      x: div(width - 100, 2),
      y: top
    )
    |> Image.write!(source)

    Logo.company_tile(source, Keyword.take(opts, [:center]))
  end

  defp logo_width(tile) do
    {:ok, trimmed} = Image.trim(tile, background: @white, threshold: 24)
    Image.width(trimmed)
  end

  defp logo_area(tile) do
    {:ok, trimmed} = Image.trim(tile, background: @white, threshold: 24)
    Image.width(trimmed) * Image.height(trimmed) / (240 * 120)
  end
end
