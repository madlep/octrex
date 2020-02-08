defmodule Octrex.BoundingBox do
  @moduledoc """
  represents an axis-aligned bounding box in 3D space.

  The min and max represent the max extent of the x/y/z co-ords in each direction
  """
  alias Octrex.Vector3

  @type t() :: {min :: Vector3.t(), max :: Vector3.t()}

  @spec new(min :: Vector3.t(), max :: Vector3.t()) :: t()
  def new(min, max) do
    {min, max}
  end

  @spec min(t()) :: Vector3.t()
  def min({min, _max}) do
    min
  end

  @spec max(t()) :: Vector3.t()
  def max({_min, max}) do
    max
  end

  @spec expand(b1 :: t(), b2 :: t()) :: t()
  def expand({b1_min, b1_max}, {b2_min, b2_max}) do
    {Vector3.min(b1_min, b2_min), Vector3.max(b1_max, b2_max)}
  end

  @spec overflow(t(), Vector3.t()) :: t()
  def overflow({{x_min, y_min, z_min}, {x_max, y_max, z_max}}, {x, y, z}) do
    {new_x_min, new_x_max} = overflow_axis(x_min, x_max, x)
    {new_y_min, new_y_max} = overflow_axis(y_min, y_max, y)
    {new_z_min, new_z_max} = overflow_axis(z_min, z_max, z)

    {{new_x_min, new_y_min, new_z_min}, {new_x_max, new_y_max, new_z_max}}
  end

  @spec overflow_axis(a_min :: number(), a_max :: number(), new_value :: number()) ::
          {new_min :: number(), new_max :: number()}
  defp overflow_axis(a_min, a_max, new_value) do
    cond do
      new_value < a_min ->
        {a_min - (a_max - new_value) * 2, a_max}

      new_value > a_max ->
        {a_min, a_max + (new_value - a_min) * 2}

      true ->
        {a_min, a_max}
    end
  end

  @spec contains(t(), location :: Vector3.t()) :: boolean()
  def contains({{x_min, y_min, z_min}, {x_max, y_max, z_max}}, {x, y, z}) do
    x_min <= x && x <= x_max &&
      y_min <= y && y <= y_max &&
      z_min <= z && z <= z_max
  end

  @spec intersects(b1 :: t(), b2 :: t()) :: boolean()
  def intersects(
        {{x1_min, y1_min, z1_min}, {x1_max, y1_max, z1_max}},
        {{x2_min, y2_min, z2_min}, {x2_max, y2_max, z2_max}}
      ) do
    # For an AABB defined by M,N against one defined by O,P they do not
    # intersect if (Mx>Px) or (Ox>Nx) or (My>Py) or (Oy>Ny) or (Mz>Pz) or
    # (Oz>Nz)
    mx = x1_min
    my = y1_min
    mz = z1_min
    nx = x1_max
    ny = y1_max
    nz = z1_max

    ox = x2_min
    oy = y2_min
    oz = z2_min
    px = x2_max
    py = y2_max
    pz = z2_max

    !(mx > px || ox > nx || my > py || oy > ny || mz > pz || oz > nz)
  end

  @spec split(t()) :: {
          x0y0z0 :: t(),
          x0y0z1 :: t(),
          x0y1z0 :: t(),
          x0y1z1 :: t(),
          x1y0z0 :: t(),
          x1y0z1 :: t(),
          x1y1z0 :: t(),
          x1y1z1 :: t()
        }
  def split({{x_min, y_min, z_min}, {x_max, y_max, z_max}}) do
    x_mid = x_min + d(x_max - x_min, 2)
    y_mid = y_min + d(y_max - y_min, 2)
    z_mid = z_min + d(z_max - z_min, 2)

    x0y0z0 = {{x_min, y_min, z_min}, {x_mid, y_mid, z_mid}}
    x0y0z1 = {{x_min, y_min, z_mid}, {x_mid, y_mid, z_max}}
    x0y1z0 = {{x_min, y_mid, z_min}, {x_mid, y_max, z_mid}}
    x0y1z1 = {{x_min, y_mid, z_mid}, {x_mid, y_max, z_max}}
    x1y0z0 = {{x_mid, y_min, z_min}, {x_max, y_mid, z_mid}}
    x1y0z1 = {{x_mid, y_min, z_mid}, {x_max, y_mid, z_max}}
    x1y1z0 = {{x_mid, y_mid, z_min}, {x_max, y_max, z_mid}}
    x1y1z1 = {{x_mid, y_mid, z_mid}, {x_max, y_max, z_max}}

    {
      x0y0z0,
      x0y0z1,
      x0y1z0,
      x0y1z1,
      x1y0z0,
      x1y0z1,
      x1y1z0,
      x1y1z1
    }
  end

  defp d(dividend, divisor) when is_integer(dividend) and is_integer(divisor) do
    div(dividend, divisor)
  end

  defp d(dividend, divisor) when is_float(dividend) do
    dividend / divisor
  end
end
