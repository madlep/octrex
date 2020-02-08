defmodule Octrex do
  @moduledoc """
  data structure for representing points in 3D space and querying them efficiently
  """

  alias Octrex.{BoundingBox, Vector3}

  @typep children(t) :: {
           x0y0z0 :: t(t),
           x0y0z1 :: t(t),
           x0y1z0 :: t(t),
           x0y1z1 :: t(t),
           x1y0z0 :: t(t),
           x1y0z1 :: t(t),
           x1y1z0 :: t(t),
           x1y1z1 :: t(t)
         }

  @type value(t) :: {location :: Vector3.t(), value :: t}

  @opaque t() :: {[], :none, :pending}
  @opaque t(t) :: {
            values :: list(value(t)),
            bounds :: :none | BoundingBox.t(),
            children :: :pending | children(t)
          }

  @type match_fn() :: (BoundingBox.t() | Vector3.t() -> boolean())

  @spec new() :: t()
  def new do
    {[], :none, :pending}
  end

  @spec insert(t(t), location :: Vector3.t(), value :: t) :: t(t) when t: var
  def insert(octrex = {[], :none, :pending}, location, value) do
    octrex
    |> put_elem(1, BoundingBox.new(location, location))
    |> put_elem(0, [{location, value}])
  end

  def insert(octrex = {values, bounds, _children}, location, value) do
    if BoundingBox.contains(bounds, location) do
      octrex
      |> put_elem(0, [{location, value} | values])
    else
      new_values = [{location, value} | to_list(octrex)]
      {new_values, BoundingBox.overflow(bounds, location), :pending}
    end
  end

  @spec to_list(t(t)) :: [value(t)] when t: var
  def to_list({values, _bounds, :pending}) do
    values
  end

  def to_list({values, _bounds, children}) do
    {c0, c1, c2, c3, c4, c5, c6, c7} = children
    l0 = to_list(c0)
    l1 = to_list(c1)
    l2 = to_list(c2)
    l3 = to_list(c3)
    l4 = to_list(c4)
    l5 = to_list(c5)
    l6 = to_list(c6)
    l7 = to_list(c7)

    values ++ l0 ++ l1 ++ l2 ++ l3 ++ l4 ++ l5 ++ l6 ++ l7
  end

  @spec find_matching(t(t), match_fn()) :: list(value(t)) when t: var
  def find_matching({[], _bounds, :pending}, _match_fn) do
    []
  end

  def find_matching({values, bounds, children}, match_fn) do
    if match_fn.(bounds) do
      matches =
        values
        |> Enum.filter(fn {location, _value} -> match_fn.(location) end)

      child_matches =
        if children == :pending do
          []
        else
          {c0, c1, c2, c3, c4, c5, c6, c7} = children
          m0 = find_matching(c0, match_fn)
          m1 = find_matching(c1, match_fn)
          m2 = find_matching(c2, match_fn)
          m3 = find_matching(c3, match_fn)
          m4 = find_matching(c4, match_fn)
          m5 = find_matching(c5, match_fn)
          m6 = find_matching(c6, match_fn)
          m7 = find_matching(c7, match_fn)
          m0 ++ m1 ++ m2 ++ m3 ++ m4 ++ m5 ++ m6 ++ m7
        end

      matches ++ child_matches
    else
      []
    end
  end

  @spec read_optimise(t(t), max_node_size :: pos_integer()) :: t(t) when t: var
  # number of values in node is OK, and no children. No need to split
  def read_optimise(octrex = {values, _bounds, :pending}, max_node_size)
      when length(values) <= max_node_size do
    octrex
  end

  def read_optimise(octrex = {values, bounds, :pending}, max_node_size)
      when length(values) > max_node_size do
    # handle case when node has too many values, but no children and needs to be split
    {bb0, bb1, bb2, bb3, bb4, bb5, bb6, bb7} =
      bounds
      |> BoundingBox.split()

    children = {
      {[], bb0, :pending},
      {[], bb1, :pending},
      {[], bb2, :pending},
      {[], bb3, :pending},
      {[], bb4, :pending},
      {[], bb5, :pending},
      {[], bb6, :pending},
      {[], bb7, :pending}
    }

    octrex
    |> put_elem(2, children)
    |> read_optimise(max_node_size)
  end

  def read_optimise({values, bounds, children}, max_node_size)
      when length(values) > 0 and children != :pending do
    # always split values into children if children are present - values can only live at leaf nodes
    {c0, c1, c2, c3, c4, c5, c6, c7} = children
    remaining = values
    {c0, remaining} = split_into_octrex(c0, remaining, max_node_size)
    {c1, remaining} = split_into_octrex(c1, remaining, max_node_size)
    {c2, remaining} = split_into_octrex(c2, remaining, max_node_size)
    {c3, remaining} = split_into_octrex(c3, remaining, max_node_size)
    {c4, remaining} = split_into_octrex(c4, remaining, max_node_size)
    {c5, remaining} = split_into_octrex(c5, remaining, max_node_size)
    {c6, remaining} = split_into_octrex(c6, remaining, max_node_size)
    {c7, []} = split_into_octrex(c7, remaining, max_node_size)

    populated_children = {c0, c1, c2, c3, c4, c5, c6, c7}

    {[], bounds, populated_children}
  end

  def read_optimise(octrex = {[], _bounds, children}, max_node_size) do
    {c0, c1, c2, c3, c4, c5, c6, c7} = children

    optimised_children = {
      read_optimise(c0, max_node_size),
      read_optimise(c1, max_node_size),
      read_optimise(c2, max_node_size),
      read_optimise(c3, max_node_size),
      read_optimise(c4, max_node_size),
      read_optimise(c5, max_node_size),
      read_optimise(c6, max_node_size),
      read_optimise(c7, max_node_size)
    }

    octrex
    |> put_elem(2, optimised_children)
  end

  @spec split_into_octrex(t(t), list(value(t)), max_node_size :: pos_integer()) ::
          {t(t), remaining :: list(value(t))}
        when t: var
  defp split_into_octrex(octrex = {values, bounds, _children}, pending_values, max_node_size) do
    {in_tree, not_in_tree} =
      pending_values
      |> Enum.split_with(fn {location, _value} -> BoundingBox.contains(bounds, location) end)

    new_octrex =
      octrex
      |> put_elem(0, in_tree ++ values)
      |> read_optimise(max_node_size)

    {new_octrex, not_in_tree}
  end
end
