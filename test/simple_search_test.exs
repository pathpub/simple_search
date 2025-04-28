defmodule SimpleSearchTest do
  use ExUnit.Case
  doctest SimpleSearch

  test "indexes and queries" do
    segment = SimpleSearchFixtures.create_segment()

    assert SimpleSearch.search(segment, "Path.pub") == [{2, 4}]
    assert MapSet.new(SimpleSearch.search(segment, "run")) == MapSet.new([{3, 1}, {4, 1}])
    assert MapSet.new(SimpleSearch.search(segment, "runs")) == MapSet.new([{3, 1}, {4, 1}])
    assert MapSet.new(SimpleSearch.search(segment, "running")) == MapSet.new([{3, 1}, {4, 1}])
  end

  test "saves and loads index" do
    segment = SimpleSearchFixtures.create_segment()

    Serializer.initialize()
    Serializer.save(segment)
    segment2 = Serializer.load()

    # :timer.sleep(30_000)

    assert segment == segment2
  end
end
