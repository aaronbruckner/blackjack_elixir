defmodule Blackjack.Deck do
  alias Blackjack.Card
  @opaque t() :: list(Card.t())

  @doc """
  Returns a shuffled standard deck of 52 cards across the four suits and range of values (2 through Ace).
  All cards are unique value/suit pairs.
  """
  @spec new() :: t()
  def new() do
    for value <- [2, 3, 4, 5, 6, 7, 8, 9, 10, :jack, :queen, :king, :ace],
        suit <- [:heart, :diamond, :spade, :club] do
      Card.new(suit, value)
    end
    |> Enum.shuffle()
  end

  @doc """
  Builds a deck with the specific cards provided in the order they are provided.
  Cards earlier in the list will be pulled first.
  """
  @spec new(list(Card.t())) :: t()
  def new(cards) do
    cards
  end

  @doc """
  Pulls the top card from the deck, returning the card and the new deck without the top card.
  If the deck is empty, the returned card will be nil.
  """
  @spec pull_top_card(t(), boolean()) :: {Card.t() | nil, t()}
  def pull_top_card(deck, face_down \\ false)

  def pull_top_card([card | remainingDeck], face_down) do
    {%Card{card | face_down: face_down}, remainingDeck}
  end

  def pull_top_card(deck, _face_down) do
    {nil, deck}
  end
end
