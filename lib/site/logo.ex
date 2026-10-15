defmodule Site.Logo do
  @moduledoc """
  Builds the client/project logo tiles of the resume (`cl-<slug>.png`):
  240×120, plain background, logo centered.

  The background is the color of the source's top-left pixel (white when it
  is transparent). The logo is trimmed to its content and scaled to cover
  about 20% of the tile, within 70% of its width and 46% of its height, so
  every tile looks about the same size. `boost` enlarges logos that look
  small at that size (thin or mostly empty marks).

  Uses the `image` library (libvips), a dev/test dependency.
  """

  @width 240
  @height 120
  @area 0.20
  @max_width 0.70
  @max_height 0.46
  @white [255, 255, 255]

  @doc "Returns the tile for the logo in `source` (a path). Options: `:boost` (default 1.0)."
  def client_tile(source, opts \\ []) do
    boost = Keyword.get(opts, :boost, 1.0)
    logo = Image.open!(source)
    background = background(logo)

    content =
      logo
      |> flatten(background)
      |> trim(background)

    scaled = Image.resize!(content, scale(content, boost))

    @width
    |> Image.new!(@height, color: background)
    |> Image.compose!(scaled,
      x: div(@width - Image.width(scaled), 2),
      y: div(@height - Image.height(scaled), 2)
    )
  end

  @doc ~s(File name of a client/project tile, e.g. "Total Bank" -> "cl-total-bank.png".)
  def client_file(name), do: "cl-" <> Site.ResumeView.slug(name) <> ".png"

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
      :math.sqrt(@area * boost * @width * @height / (width * height)),
      @max_width * grow * @width / width,
      @max_height * grow * @height / height
    ])
  end
end
