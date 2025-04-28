defmodule SimpleSearchFixtures do
  def create_segment() do
    SimpleSearch.new_segment()
    |> SimpleSearch.index_all([
      {1, "The cat is a tumbler"},
      {2, "I'm reading on Path.pub"},
      {3, "Where do we store the test runs?"},
      {4, "Running to better understanding"},
    ])
  end
end
