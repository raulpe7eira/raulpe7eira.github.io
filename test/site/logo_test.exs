defmodule Site.LogoTest do
  use ExUnit.Case, async: true

  alias Site.Logo

  @moduletag :tmp_dir

  @white [255, 255, 255]
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
  end

  describe "client_file/1" do
    test "slugs the name" do
      assert Logo.client_file("Total Bank") == "cl-total-bank.png"
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

  defp logo_area(tile) do
    {:ok, trimmed} = Image.trim(tile, background: @white, threshold: 24)
    Image.width(trimmed) * Image.height(trimmed) / (240 * 120)
  end
end
