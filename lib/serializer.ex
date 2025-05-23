defmodule Serializer do
  @moduledoc """
    This module handles the serialization and deserialization of the inverted
    index.  This is an asynchronous process and otherwise the assumption is
    regular operations for simple search happen in-memory.
  """
  @spec initialize() :: {:aborted, any()} | {:atomic, :ok}
  def initialize() do
    :mnesia.stop()
    :mnesia.create_schema([node()])
    :mnesia.start()
    :mnesia.create_table(InvertedIndex, attributes: [:term, :docs])
    :mnesia.create_table(InvertedIndexBigrams, attributes: [:term, :docs])
    :mnesia.create_table(InvertedIndexUnstemmed, attributes: [:term, :docs])
  end

  @spec start() :: :ok | {:error, any()}
  def start() do
    :mnesia.start()
  end

  @spec save(SimpleSearch.segment()) :: :ok | {:error, any()}
  def save({unigram_idx, bigram_idx, unstemmed_unigram_idx, _trie} = _segment) do
    Enum.each(unigram_idx, fn {term, docs} ->
      :mnesia.dirty_write({InvertedIndex, term, docs})
    end)

    Enum.each(bigram_idx, fn {term, docs} ->
      :mnesia.dirty_write({InvertedIndexBigrams, term, docs})
    end)

    Enum.each(unstemmed_unigram_idx, fn {term, docs} ->
      :mnesia.dirty_write({InvertedIndexUnstemmed, term, docs})
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

    {:atomic, {unstemmed_unigram_idx, trie}} =
      :mnesia.transaction(fn ->
        :mnesia.foldl(
          fn {_table, term, docs}, {acc, trie} ->
            acc = Map.put(acc, term, docs)
            trie = Trieval.insert(trie, term)
            {acc, trie}
          end,
          {%{}, Trieval.new()},
          InvertedIndexUnstemmed
        )
      end)

    {unigram_idx, bigram_idx, unstemmed_unigram_idx, trie}
  end
end
