defmodule OctrexTest do
  @moduledoc """
  test Octrex
  """

  use ExUnit.Case

  alias Octrex.{BoundingBox}

  describe ".new" do
    test "it can be created" do
      assert(Octrex.new() == {[], :none, :pending})
    end
  end

  describe ".insert" do
    test "inserted values get stored at root initially" do
      octree =
        Octrex.new()
        |> Octrex.insert({1, 2, 3}, "v1")
        |> Octrex.insert({-1, -2, -3}, "v2")
        |> Octrex.insert({3, 4, 5}, "v3")

      {values, _bounds, _children} = octree

      assert(values == [{{3, 4, 5}, "v3"}, {{-1, -2, -3}, "v2"}, {{1, 2, 3}, "v1"}])
    end

    test "initial value sets zero size bounding box around at location" do
      octree =
        Octrex.new()
        |> Octrex.insert({1, 2, 3}, "v1")

      {_values, bounds, _children} = octree
      assert(bounds == {{1, 2, 3}, {1, 2, 3}})
    end

    test "further values outside bounds overflows bounds" do
      octree =
        Octrex.new()
        |> Octrex.insert({1, 2, 3}, "v1")
        |> Octrex.insert({1, 2, 8}, "v2")
        |> Octrex.insert({-8, 2, 8}, "v3")

      {_values, bounds, _children} = octree
      assert(bounds == {{-17, 2, 3}, {1, 2, 13}})
    end

    test "insert a bunch of stuff" do
      octree = Octrex.new()

      # start = :erlang.monotonic_time(:microsecond)

      octree =
        1..1_000_000
        |> Enum.reduce(octree, fn v, o ->
          location =
            {:rand.uniform(100_000) - 50_000, :rand.uniform(100_000) - 50_000,
             :erlang.unique_integer([:positive, :monotonic])}

          Octrex.insert(o, location, v)
        end)

      # IO.puts("finished build tree, #{:erlang.monotonic_time(:microsecond) - start}")

      # start = :erlang.monotonic_time(:microsecond)
      octree = Octrex.read_optimise(octree, 20)

      # IO.puts("finished read_optimise, #{:erlang.monotonic_time(:microsecond) - start}")

      expected_results = [
        {{100, 100, z_start = :erlang.unique_integer([:positive, :monotonic])}, "e1"},
        {{190, 110, :erlang.unique_integer([:positive, :monotonic])}, "e2"},
        {{120, 180, :erlang.unique_integer([:positive, :monotonic])}, "e3"},
        {{170, 120, :erlang.unique_integer([:positive, :monotonic])}, "e4"},
        {{130, 170, :erlang.unique_integer([:positive, :monotonic])}, "e5"},
        {{160, 130, :erlang.unique_integer([:positive, :monotonic])}, "e6"},
        {{140, 160, :erlang.unique_integer([:positive, :monotonic])}, "e7"},
        {{150, 150, z_finish = :erlang.unique_integer([:positive, :monotonic])}, "e8"}
      ]

      octree =
        expected_results
        |> Enum.reduce(octree, fn {location, value}, o -> Octrex.insert(o, location, value) end)

      # start = :erlang.monotonic_time(:microsecond)

      octree =
        1..1000
        |> Enum.reduce(octree, fn v, o ->
          location =
            {:rand.uniform(100_000) - 50_000, :rand.uniform(100_000) - 50_000,
             :erlang.unique_integer([:positive, :monotonic])}

          Octrex.insert(o, location, v)
        end)

      # IO.puts("finish update tree, #{:erlang.monotonic_time(:microsecond) - start}")

      # start = :erlang.monotonic_time(:microsecond)
      octree = octree = Octrex.read_optimise(octree, 10)
      # IO.puts("finished read_optimise, #{:erlang.monotonic_time(:microsecond) - start}")

      # start = :erlang.monotonic_time(:microsecond)
      octree = octree = Octrex.read_optimise(octree, 10)

      # IO.puts("finished no-op read_optimise, #{:erlang.monotonic_time(:microsecond) - start}")

      # start = :erlang.monotonic_time(:microsecond)

      target = BoundingBox.new({100, 100, z_start}, {200, 200, z_finish})

      matching =
        octree
        |> Octrex.find_matching(fn
          v = {_x, _y, _z} ->
            BoundingBox.contains(target, v)

          bb ->
            BoundingBox.intersects(target, bb)
        end)
        |> Enum.sort_by(fn {_location, value} -> value end)

      # IO.puts("finish find_matching, #{:erlang.monotonic_time(:microsecond) - start}")

      assert(matching == expected_results)
    end
  end
end
