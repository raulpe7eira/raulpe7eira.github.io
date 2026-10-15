defmodule Site.PhotoTest do
  use ExUnit.Case, async: true

  alias Site.Photo

  @moduletag :tmp_dir

  describe "favicons/1" do
    test "builds every favicon", %{tmp_dir: dir} do
      assert dir |> favicons() |> Map.keys() |> Enum.sort() == [
               "assets/images/icons/apple-touch-icon.png",
               "assets/images/icons/favicon-96x96.png",
               "assets/images/icons/favicon.svg",
               "assets/images/icons/icon-192.png",
               "assets/images/icons/icon-512.png",
               "favicon.ico"
             ]
    end

    test "puts 16, 32 and 48 pixel images in the favicon", %{tmp_dir: dir} do
      assert <<0::16, 1::little-16, 3::little-16, 16, 16, _first::binary-size(14), 32, 32,
               _second::binary-size(14), 48, 48, _rest::binary>> =
               dir |> favicons() |> Map.fetch!("favicon.ico")
    end

    test "points the favicon entries at PNG images", %{tmp_dir: dir} do
      <<_header::binary-size(18), offset::little-32, _rest::binary>> =
        favicon = dir |> favicons() |> Map.fetch!("favicon.ico")

      assert <<0x89, "PNG", _png::binary>> = binary_part(favicon, offset, 8)
    end

    test "embeds a JPEG of the photo in the SVG favicon", %{tmp_dir: dir} do
      assert dir |> favicons() |> Map.fetch!("assets/images/icons/favicon.svg") =~
               ~s(href="data:image/jpeg;base64,)
    end

    test "builds the PNG favicon at 96 pixels", %{tmp_dir: dir} do
      assert dir |> favicon("assets/images/icons/favicon-96x96.png") |> Image.width() == 96
    end

    test "builds the apple touch icon at 180 pixels", %{tmp_dir: dir} do
      assert dir |> favicon("assets/images/icons/apple-touch-icon.png") |> Image.width() == 180
    end

    test "builds the manifest icons at 192 and 512 pixels", %{tmp_dir: dir} do
      icons = ["assets/images/icons/icon-192.png", "assets/images/icons/icon-512.png"]
      assert Enum.map(icons, &(dir |> favicon(&1) |> Image.width())) == [192, 512]
    end

    test "puts a transparent photo on white", %{tmp_dir: dir} do
      source = Path.join(dir, "transparent.png")
      512 |> Image.new!(512, color: [0, 0, 0, 0]) |> Image.write!(source)

      icon =
        source
        |> Photo.favicons()
        |> Map.new()
        |> Map.fetch!("assets/images/icons/icon-512.png")
        |> Image.from_binary!()

      assert {:ok, [255, 255, 255]} = Image.get_pixel(icon, 0, 0)
    end

    test "crops a non-square photo to a square", %{tmp_dir: dir} do
      assert dir |> favicon("assets/images/icons/icon-512.png", 600) |> Image.height() == 512
    end
  end

  describe "avatar/1" do
    test "builds only the avatar", %{tmp_dir: dir} do
      assert dir |> photo(&Photo.avatar/1) |> Map.keys() == ["assets/images/avatar.jpg"]
    end

    test "builds the avatar at 240 pixels", %{tmp_dir: dir} do
      avatar =
        dir
        |> photo(&Photo.avatar/1)
        |> Map.fetch!("assets/images/avatar.jpg")
        |> Image.from_binary!()

      assert Image.width(avatar) == 240
    end
  end

  defp favicons(dir, width \\ 512), do: photo(dir, &Photo.favicons/1, width)

  defp favicon(dir, path, width \\ 512) do
    dir |> favicons(width) |> Map.fetch!(path) |> Image.from_binary!()
  end

  defp photo(dir, build, width \\ 512) do
    source = Path.join(dir, "photo-#{width}.jpg")
    width |> Image.new!(512, color: [200, 120, 80]) |> Image.write!(source)
    source |> build.() |> Map.new()
  end
end
