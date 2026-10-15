defmodule Site.Icons do
  @moduledoc """
  Builds the site icons from one square photo, so they always match:

    * `favicon.ico` at the site root, with 16, 32 and 48 pixel PNGs inside
    * `assets/images/icons/favicon.svg`, a 96 pixel JPEG of the photo inside
      an SVG (Chrome, Edge and Firefox prefer an SVG favicon)
    * `assets/images/icons/favicon-96x96.png`, the PNG favicon for desktop
      browsers and search results
    * `assets/images/icons/apple-touch-icon.png` (180), for iOS home screens
    * `assets/images/icons/icon-192.png` and `icon-512.png`, for the web
      manifest (Android)
    * `assets/images/avatar.jpg` (240, twice the 120 pixels the page shows)

  A non-square photo is cropped to its center.

  Uses the `image` library (libvips), a dev/test dependency.
  """

  @favicon "favicon.ico"
  @favicon_sizes [16, 32, 48]
  @pngs [
    {"assets/images/icons/favicon-96x96.png", 96},
    {"assets/images/icons/apple-touch-icon.png", 180},
    {"assets/images/icons/icon-192.png", 192},
    {"assets/images/icons/icon-512.png", 512}
  ]
  @svg {"assets/images/icons/favicon.svg", 96}
  @avatar {"assets/images/avatar.jpg", 240}
  @white [255, 255, 255]

  @doc "Returns `{path, binary}` for every icon built from the photo in `source`; paths are relative to `docs/`."
  def build(source) do
    photo = source |> Image.open!() |> square()
    {svg, svg_size} = @svg
    {avatar, avatar_size} = @avatar

    favicon =
      ico(for size <- @favicon_sizes, do: {size, encode(photo, size, ".png")})

    pngs = for {path, size} <- @pngs, do: {path, encode(photo, size, ".png")}

    [{@favicon, favicon}, {svg, svg_favicon(encode(photo, svg_size, ".jpg"), svg_size)}] ++
      pngs ++ [{avatar, encode(photo, avatar_size, ".jpg")}]
  end

  defp square(photo) do
    side = min(Image.width(photo), Image.height(photo))
    left = div(Image.width(photo) - side, 2)
    top = div(Image.height(photo) - side, 2)
    cropped = Image.crop!(photo, left, top, side, side)

    if Image.has_alpha?(cropped),
      do: Image.flatten!(cropped, background: @white),
      else: cropped
  end

  defp encode(photo, size, suffix) do
    photo
    |> Image.thumbnail!(size)
    |> Image.write!(:memory, suffix: suffix)
  end

  # an SVG that only wraps the JPEG, so browsers that prefer SVG favicons get the photo
  defp svg_favicon(jpeg, size) do
    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{size} #{size}">\
    <image width="#{size}" height="#{size}" href="data:image/jpeg;base64,#{Base.encode64(jpeg)}"/></svg>
    """
  end

  # an ICO file holding PNG images: a header, one directory entry per image,
  # then the images themselves
  defp ico(images) do
    count = length(images)

    {entries, data, _offset} =
      Enum.reduce(images, {<<>>, <<>>, 6 + 16 * count}, fn {size, png}, {entries, data, offset} ->
        entry =
          <<size::8, size::8, 0::8, 0::8, 1::little-16, 32::little-16, byte_size(png)::little-32,
            offset::little-32>>

        {entries <> entry, data <> png, offset + byte_size(png)}
      end)

    <<0::little-16, 1::little-16, count::little-16>> <> entries <> data
  end
end
