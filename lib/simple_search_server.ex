defmodule SimpleSearchServer do
  @moduledoc """
  Documentation for `SimpleSearchServer`.

  This module provides a GenServer version of the search server
  """

  use GenServer

  @doc """
  Starts the SimpleSearchServer with an initial empty segment.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Indexes a list of documents.
  """
  def index(document) do
    GenServer.cast(__MODULE__, {:index, document})
  end

  def suggest(query) do
    GenServer.call(__MODULE__, {:suggest, query})
  end

  def search(query) do
    GenServer.call(__MODULE__, {:search, query})
  end

  @doc """
  Initializes the server with an empty segment.
  """
  @impl true
  def init(_) do
    {:ok, SimpleSearch.new_segment()}
  end

  @impl true
  def handle_cast({:index, {doc_id, text}}, segment) do
    new_segment = SimpleSearch.index_one(segment, {doc_id, text})
    {:noreply, new_segment}
  end

  @impl true
  def handle_cast({:index_all, documents}, segment) do
    new_segment = SimpleSearch.index_all(segment, documents)
    {:noreply, new_segment}
  end

  @impl true
  def handle_call({:index, {doc_id, text}}, _from, segment) do
    new_segment = SimpleSearch.index_one(segment, {doc_id, text})
    {:reply, :ok, new_segment}
  end

  @impl true
  def handle_call({:suggest, query}, _from, segment) do
    {:reply, SimpleSearch.suggest(segment, query), segment}
  end

  @impl true
  def handle_call({:search, query}, _from, segment) do
    {:reply, SimpleSearch.search(segment, query), segment}
  end
end
