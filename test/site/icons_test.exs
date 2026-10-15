defmodule Site.IconsTest do
  use ExUnit.Case, async: true

  alias Site.Icons

  @moduletag :tmp_dir

  describe "build/1" do
    test "builds every icon and the avatar", %{tmp_dir: dir} do
      assert dir |> icons() |> Map.keys() |> Enum.sort() == [
               "assets/images/avatar.jpg",
               "assets/images/icons/apple-touch-icon.png",
               "assets/images/icons/icon-192.png",
               "assets/images/icons/icon-512.png",
               "favicon.ico"
             ]
    end

    test "puts 16 and 32 pixel images in the favicon", %{tmp_dir: dir} do
      assert <<0::16, 1::little-16, 2::little-16, 16, 16, _first::binary-size(14), 32, 32,
               _rest::binary>> = dir |> icons() |> Map.fetch!("favicon.ico")
    end

    test "points the favicon entries at PNG images", %{tmp_dir: dir} do
      <<_header::binary-size(18), offset::little-32, _rest::binary>> =
        favicon = dir |> icons() |> Map.fetch!("favicon.ico")

      assert <<0x89, "PNG", _png::binary>> = binary_part(favicon, offset, 8)
    end

    test "builds the apple touch icon at 180 pixels", %{tmp_dir: dir} do
      assert dir |> icon("assets/images/icons/apple-touch-icon.png") |> Image.width() == 180
    end

    test "builds the manifest icons at 192 and 512 pixels", %{tmp_dir: dir} do
      icons = ["assets/images/icons/icon-192.png", "assets/images/icons/icon-512.png"]
      assert Enum.map(icons, &(dir |> icon(&1) |> Image.width())) == [192, 512]
    end

    test "builds the avatar at 240 pixels", %{tmp_dir: dir} do
      assert dir |> icon("assets/images/avatar.jpg") |> Image.width() == 240
    end

    test "puts a transparent photo on white", %{tmp_dir: dir} do
      source = Path.join(dir, "transparent.png")
      512 |> Image.new!(512, color: [0, 0, 0, 0]) |> Image.write!(source)

      icon =
        source
        |> Icons.build()
        |> Map.new()
        |> Map.fetch!("assets/images/icons/icon-512.png")
        |> Image.from_binary!()

      assert {:ok, [255, 255, 255]} = Image.get_pixel(icon, 0, 0)
    end

    test "crops a non-square photo to a square", %{tmp_dir: dir} do
      assert dir |> icon("assets/images/icons/icon-512.png", 600) |> Image.height() == 512
    end
  end

  defp icons(dir, width \\ 512) do
    source = Path.join(dir, "photo-#{width}.jpg")
    width |> Image.new!(512, color: [200, 120, 80]) |> Image.write!(source)
    source |> Icons.build() |> Map.new()
  end

  defp icon(dir, path, width \\ 512) do
    dir |> icons(width) |> Map.fetch!(path) |> Image.from_binary!()
  end
end
