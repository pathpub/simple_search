defmodule SimpleSearch do
  @moduledoc """
  Documentation for `Simplesearch`.

  Given a list of documents =
  [{1, "some text here"},
    2, "more text here"}]

  You can index by running:
    segment = SimpleSearch.index_all(documents)

  Then query:
    SimpleSearch.search(segment, "your search query")
  """

  @type segment :: {map(), map()}

  @spec new_segment() :: segment()
  def new_segment() do
    {%{}, %{}}
  end

  @spec index_all(segment(), [{integer(), String.t()}]) :: segment()
  def index_all(segment, documents) do
    Enum.reduce(documents, segment, fn document, segment ->
      SimpleSearch.index_one(segment, document)
    end)
  end

  @spec index_one(segment(), {integer(), String.t()}) :: segment()
  def index_one(segment, {doc_id, text}) do
    unigrams = doc2tokens(text)
    bigrams = Enum.chunk_every(unigrams, 2, 1, :discard)

    {unigram_index, bigram_index} = segment

    unigram_index =
      Enum.reduce(unigrams, unigram_index, fn token, unigram_index ->
        Map.update(unigram_index, token, MapSet.new([doc_id]), fn ms ->
          MapSet.put(ms, doc_id)
        end)
      end)

    bigram_index =
      Enum.reduce(bigrams, bigram_index, fn [gram1, gram2], bigram_index ->
        token = "#{gram1}_#{gram2}"

        Map.update(bigram_index, token, MapSet.new([doc_id]), fn ms ->
          MapSet.put(ms, doc_id)
        end)
      end)

    {unigram_index, bigram_index}
  end

  @spec doc2tokens(String.t()) :: [String.t()]
  def doc2tokens(document) do
    String.downcase(document)
    |> strip_punctuation()
    |> String.split()
    |> Enum.map(fn token ->
      Stemmer.stem(token)
    end)
  end

  @spec strip_punctuation(String.t()) :: String.t()
  def strip_punctuation(document) do
    String.replace(document, ~r/[[:punct:]]/, " ")
  end

  @spec unigrams2bigrams([String.t()]) :: [String.t()]
  def unigrams2bigrams(unigrams) do
    Enum.chunk_every(unigrams, 2, 1, :discard)
    |> Enum.map(fn [a, b] -> "#{a}_#{b}" end)
  end

  # returns a desc sorted list of {doc_id, score}
  @spec search({any(), any()}, binary()) :: [{integer(), integer()}]
  def search(segment, query) do
    {unigram_idx, bigram_idx} = segment

    unigram_terms = doc2tokens(query)
    bigram_terms = unigrams2bigrams(unigram_terms)

    # get all the matching doc_ids for each term
    unigram_matches =
      Enum.flat_map(unigram_terms, fn term ->
        MapSet.to_list(Map.get(unigram_idx, term, MapSet.new()))
      end)

    # score matches
    doc_scores =
      if Enum.empty?(unigram_matches) do
        %{}
      else
        Enum.reduce(
          unigram_matches,
          %{},
          fn e, acc ->
            Map.update(acc, e, 1, fn count -> count + 1 end)
          end
        )
      end

    bigram_matches =
      Enum.flat_map(bigram_terms, fn term ->
        MapSet.to_list(Map.get(bigram_idx, term, MapSet.new()))
      end)

    doc_scores =
      if Enum.empty?(bigram_matches) do
        doc_scores
      else
        Enum.reduce(
          bigram_matches,
          doc_scores,
          fn e, acc ->
            Map.update(acc, e, 2, fn count -> count + 2 end)
          end
        )
      end

    Enum.sort_by(doc_scores, fn {_key, value} -> value end, :desc)
  end
end
