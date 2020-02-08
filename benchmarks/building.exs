Benchee.run(
  %{
    "insert" => fn input ->
      octree = Octrex.new()

      1..input
      |> Enum.reduce(octree, fn v, o ->
        location =
          {:rand.uniform(100_000) - 50_000, :rand.uniform(100_000) - 50_000,
           :erlang.unique_integer([:positive, :monotonic])}

        Octrex.insert(o, location, v)
      end)
    end
  },
  inputs: %{
    "10" => 10,
    "100" => 100,
    "1000" => 1_000,
    "10000" => 10_000,
    "100000" => 100_000
  }
)

# octree =
#   1..1_000_000
#   |> Enum.reduce(octree, fn v, o ->
#     location =
#       {:rand.uniform(100_000) - 50_000, :rand.uniform(100_000) - 50_000,
#         :erlang.unique_integer([:positive, :monotonic])}
#
#     Octree.insert(o, location, v)
#   end)
#
# # IO.puts("finished build tree, #{:erlang.monotonic_time(:microsecond) - start}")
#
# # start = :erlang.monotonic_time(:microsecond)
# octree = Octree.read_optimise(octree, 20)
#
# # IO.puts("finished read_optimise, #{:erlang.monotonic_time(:microsecond) - start}")
#
# expected_results = [
#   {{100, 100, z_start = :erlang.unique_integer([:positive, :monotonic])}, "e1"},
#   {{190, 110, :erlang.unique_integer([:positive, :monotonic])}, "e2"},
#   {{120, 180, :erlang.unique_integer([:positive, :monotonic])}, "e3"},
#   {{170, 120, :erlang.unique_integer([:positive, :monotonic])}, "e4"},
#   {{130, 170, :erlang.unique_integer([:positive, :monotonic])}, "e5"},
#   {{160, 130, :erlang.unique_integer([:positive, :monotonic])}, "e6"},
#   {{140, 160, :erlang.unique_integer([:positive, :monotonic])}, "e7"},
#   {{150, 150, z_finish = :erlang.unique_integer([:positive, :monotonic])}, "e8"}
# ]
#
# octree =
#   expected_results
#   |> Enum.reduce(octree, fn {location, value}, o -> Octree.insert(o, location, value) end)
#
# # start = :erlang.monotonic_time(:microsecond)
#
# octree =
#   1..1000
#   |> Enum.reduce(octree, fn v, o ->
#     location =
#       {:rand.uniform(100_000) - 50_000, :rand.uniform(100_000) - 50_000,
#         :erlang.unique_integer([:positive, :monotonic])}
#
#     Octree.insert(o, location, v)
#   end)
#
# # IO.puts("finish update tree, #{:erlang.monotonic_time(:microsecond) - start}")
#
# # start = :erlang.monotonic_time(:microsecond)
# octree = octree = Octree.read_optimise(octree, 10)
# # IO.puts("finished read_optimise, #{:erlang.monotonic_time(:microsecond) - start}")
#
# # start = :erlang.monotonic_time(:microsecond)
# octree = octree = Octree.read_optimise(octree, 10)
#
# # IO.puts("finished no-op read_optimise, #{:erlang.monotonic_time(:microsecond) - start}")
#
# # start = :erlang.monotonic_time(:microsecond)
#
# target = BoundingBox.new({100, 100, z_start}, {200, 200, z_finish})
#
# matching =
#   octree
#   |> Octree.find_matching(fn
#     v = {_x, _y, _z} ->
#       BoundingBox.contains(target, v)
#
#     bb ->
#       BoundingBox.intersects(target, bb)
#   end)
#   |> Enum.sort_by(fn {_location, value} -> value end)
#
# # IO.puts("finish find_matching, #{:erlang.monotonic_time(:microsecond) - start}")
#
# assert(matching == expected_results)
