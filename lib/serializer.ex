defmodule Serializer do
  @spec initialize() :: {:aborted, any()} | {:atomic, :ok}
  def initialize() do
    :mnesia.stop()
    :mnesia.create_schema([node()])
    :mnesia.start()
    :mnesia.create_table(InvertedIndex, attributes: [:term, :docs])
    :mnesia.create_table(InvertedIndexBigrams, attributes: [:term, :docs])
  end

  @spec start() :: :ok | {:error, any()}
  def start() do
    :mnesia.start()
  end

  @spec save(SimpleSearch.segment()) :: :ok | {:error, any()}
  def save({unigram_idx, bigram_idx} = _segment) do
    Enum.each(unigram_idx, fn {term, docs} ->
      :mnesia.dirty_write({InvertedIndex, term, docs})
    end)

    Enum.each(bigram_idx, fn {term, docs} ->
      :mnesia.dirty_write({InvertedIndexBigrams, term, docs})
    end)
  end

  @spec load() :: SimpleSearch.segment() | {:aborted, any()}
  def load() do
    {:atomic, unigram_idx} =
      :mnesia.transaction(fn ->
        :mnesia.foldl(
          fn {_table, term, docs}, acc ->
            Map.put(acc, term, docs)
          end,
          %{},
          InvertedIndex
        )
      end)

    {:atomic, bigram_idx} =
      :mnesia.transaction(fn ->
        :mnesia.foldl(
          fn {_table, term, docs}, acc ->
            Map.put(acc, term, docs)
          end,
          %{},
          InvertedIndexBigrams
        )
      end)

    {unigram_idx, bigram_idx}
  end
end
