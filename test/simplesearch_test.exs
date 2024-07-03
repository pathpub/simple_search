defmodule SimpleSearchTest do
  use ExUnit.Case
  doctest SimpleSearch

  def create_test_segment() do
    SimpleSearch.new_segment()
    |> SimpleSearch.index_all([
      {1, "The cat is a tumbler"},
      {2, "I'm running Perplexity.ai"},
      {3, "Where do we store the test runs?"}
    ])
  end

  test "indexes and queries" do
    segment = SimpleSearchFixtures.create_segment()

    assert SimpleSearch.search(segment, "Perplexity.ai") == [2]
    assert MapSet.new(SimpleSearch.search(segment, "run")) == MapSet.new([2, 3])
    assert MapSet.new(SimpleSearch.search(segment, "runs")) == MapSet.new([2, 3])
    assert MapSet.new(SimpleSearch.search(segment, "running")) == MapSet.new([2, 3])
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
