defmodule Site.Logo do
  @moduledoc """
  Builds the logo images of the resume, so every new one follows the same
  rule:

    * client/project tiles (`cl-<slug>.png`): 240×120, plain background,
      logo centered. The logo is trimmed to its content and scaled to cover
      about 20% of the tile, within 70% of its width and 46% of its height,
      so every tile looks about the same size. `boost` enlarges logos that
      look small at that size (thin or mostly empty marks).
    * company squares (`sq-<slug>.png`): 400×400, RGB. Company logos come
      already framed as square avatars, so the framing is kept: a square
      source is only resized, and a non-square one is cropped to its center.
      `center` recenters a logo that is off-center in its source.

  The background is the color of the source's top-left pixel (white when it
  is transparent).

  Uses the `image` library (libvips), a dev/test dependency.
  """

  @client_width 240
  @client_height 120
  @area 0.20
  @max_width 0.70
  @max_height 0.46
  @company_side 400
  @white [255, 255, 255]

  @doc "Returns the client/project tile for the logo in `source` (a path). Options: `:boost` (default 1.0)."
  def client_tile(source, opts \\ []) do
    boost = Keyword.get(opts, :boost, 1.0)
    logo = Image.open!(source)
    background = background(logo)

    content =
      logo
      |> flatten(background)
      |> trim(background)

    content
    |> Image.resize!(scale(content, boost))
    |> place(background, @client_width, @client_height)
  end

  @doc "Returns the company square for the logo in `source` (a path). Options: `:center` (default false)."
  def company_tile(source, opts \\ []) do
    logo = Image.open!(source)
    background = background(logo)
    flat = flatten(logo, background)
    side = min(Image.width(flat), Image.height(flat))

    square =
      if Keyword.get(opts, :center, false),
        do: recenter(flat, background, side),
        else: center_crop(flat, side)

    square
    |> Image.resize!(@company_side / Image.width(square))
    |> place(background, @company_side, @company_side)
    # composing adds an alpha channel; the square is opaque RGB
    |> flatten(background)
  end

  @doc ~s(File name of a client/project tile, e.g. "Total Bank" -> "cl-total-bank.png".)
  def client_file(name), do: "cl-" <> Site.ResumeView.slug(name) <> ".png"

  @doc ~s(File name of a company square, e.g. "R3M Tech" -> "sq-r3m-tech.png".)
  def company_file(name), do: "sq-" <> Site.ResumeView.slug(name) <> ".png"

  defp background(logo) do
    {:ok, pixel} = Image.get_pixel(logo, 0, 0)

    case pixel do
      [_red, _green, _blue, 0] -> @white
      [red, green, blue | _alpha] -> [red, green, blue]
    end
  end

  defp flatten(logo, background) do
    if Image.has_alpha?(logo), do: Image.flatten!(logo, background: background), else: logo
  end

  defp trim(logo, background) do
    case Image.trim(logo, background: background, threshold: 24) do
      {:ok, trimmed} -> trimmed
      # nothing but background: keep the image as it is
      {:error, _reason} -> logo
    end
  end

  defp scale(content, boost) do
    width = Image.width(content)
    height = Image.height(content)
    grow = :math.sqrt(boost)

    Enum.min([
      :math.sqrt(@area * boost * @client_width * @client_height / (width * height)),
      @max_width * grow * @client_width / width,
      @max_height * grow * @client_height / height
    ])
  end

  defp center_crop(logo, side) do
    left = div(Image.width(logo) - side, 2)
    top = div(Image.height(logo) - side, 2)
    Image.crop!(logo, left, top, side, side)
  end

  defp recenter(logo, background, side) do
    content = trim(logo, background)
    canvas = Enum.max([side, Image.width(content), Image.height(content)])
    place(content, background, canvas, canvas)
  end

  # composes `logo` centered on a `width`×`height` canvas of `background`
  defp place(logo, background, width, height) do
    width
    |> Image.new!(height, color: background)
    |> Image.compose!(logo,
      x: div(width - Image.width(logo), 2),
      y: div(height - Image.height(logo), 2)
    )
  end
end
