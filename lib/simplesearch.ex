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

  def initialize() do
    :mnesia.stop()
    :mnesia.create_schema([node()])
    :mnesia.start()
    :mnesia.create_table(InvertedIndex, attributes: [:term, :docs])
    :mnesia.create_table(InvertedIndexBigrams, attributes: [:term, :docs])
  end

  def start() do
    :mnesia.start()
  end

  @doc """
  """
  def index_all(segment, documents) do
    Enum.reduce(documents, segment, fn document, segment ->
      SimpleSearch.index_one(segment, document)
    end)
  end

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

  def doc2tokens(document) do
    String.downcase(document)
    |> strip_punctuation()
    |> String.split()
    |> Enum.map(fn token ->
      Stemmer.stem(token)
    end)
  end

  def strip_punctuation(document) do
    String.replace(document, ~r/[[:punct:]]/, " ")
  end

  def write_all(segment) do
    {unigram_index, bigram_index} = segment

    Enum.each(unigram_index, fn e ->
      :mnesia.dirty_write(InvertedIndex, e)
    end)

    Enum.each(bigram_index, fn e ->
      :mnesia.dirty_write(InvertedIndexBigrams, e)
    end)
  end

  def read_all() do
    unigram_index =
      :mnesia.transaction(fn ->
        :mnesia.foldl(
          fn rec, acc ->
            [rec | acc]
          end,
          [],
          InvertedIndex
        )
      end)

    bigram_index =
      :mnesia.transaction(fn ->
        :mnesia.foldl(
          fn rec, acc ->
            [rec | acc]
          end,
          [],
          InvertedIndexBigrams
        )
      end)

    {unigram_index, bigram_index}
  end

  # TODO: ranking based on term frequency and bigram matches
  @spec search({any(), any()}, binary()) :: list()
  def search(segment, query) do
    {unigram_idx, bigram_idx} = segment

    unigram_terms =
      Enum.map(
        String.downcase(query)
        |> strip_punctuation
        |> String.split(),
        &Stemmer.stem/1
      )

    bigram_terms = Enum.chunk_every(unigram_terms, 2, 1, :discard)

    all_matches =
      Enum.map(unigram_terms, fn term ->
        Map.get(unigram_idx, term, MapSet.new())
      end)

    unigram_matches =
      if Enum.empty?(all_matches) do
        []
      else
        Enum.reduce(
          all_matches,
          fn e, acc ->
            MapSet.intersection(e, acc)
          end
        )
      end

    all_matches =
      Enum.map(bigram_terms, fn term ->
        Map.get(bigram_idx, term, MapSet.new())
      end)

    # bigrams should be used for scoring in the future
    _bigram_matches =
      if Enum.empty?(all_matches) do
        []
      else
        Enum.reduce(
          all_matches,
          fn e, acc ->
            MapSet.intersection(e, acc)
          end
        )
      end

    MapSet.to_list(unigram_matches)
  end
end
