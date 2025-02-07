defmodule SimpleSearchFixtures do
  def create_segment() do
    SimpleSearch.new_segment()
    |> SimpleSearch.index_all([
      {1, "The cat is a tumbler"},
      {2, "I'm running Perplexity.ai"},
      {3, "Where do we store the test runs?"}
    ])
  end
end
