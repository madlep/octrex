defmodule Octrex.Vector3 do
  @moduledoc """
  a vector in 3D space
  """
  @type t() :: {x :: number(), y :: number(), z :: number()}

  @spec min(v1 :: t(), v2 :: t()) :: t()
  def min({x1, y1, z1}, {x2, y2, z2}) do
    {Kernel.min(x1, x2), Kernel.min(y1, y2), Kernel.min(z1, z2)}
  end

  @spec max(v1 :: t(), v2 :: t()) :: t()
  def max({x1, y1, z1}, {x2, y2, z2}) do
    {Kernel.max(x1, x2), Kernel.max(y1, y2), Kernel.max(z1, z2)}
  end
end
