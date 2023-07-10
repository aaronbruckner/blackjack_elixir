defmodule Blackjack.Hand do
  alias Blackjack.Card
  @opaque t() :: list(%Blackjack.Card{})

  @spec new() :: t()
  def new(), do: []

  @doc """
  Calculates the maximum score a hand can produce without going bust. The score will
  exceed 21 if bust.
  """
  @spec max_safe_score(t()) :: integer()
  def max_safe_score(hand) do
    hasAce = Enum.any?(hand, &(&1.value === :ace))

    case Enum.reduce(hand, 0, fn card, total -> total + Card.point_value(card) end) do
      # Upgrade 1 ace to 11 if we can avoid going bust.
      # We can only ever upgrade at most 1 ace without going bust.
      total when hasAce and total <= 11 -> total + 10
      total -> total
    end
  end

  @doc """
  Determines if the hand has exceeded 21 using its minimum possible value.
  """
  @spec is_bust(t()) :: boolean()
  def is_bust(hand), do: max_safe_score(hand) > 21

  @doc """
  Appends a card to the hand.
  """
  @spec add_card(t(), Card.t()) :: t()
  def add_card(hand, card), do: [card | hand]

  @doc """
  Flips all cards face-up
  """
  @spec show_cards(t()) :: t()
  def show_cards(hand) do
    Enum.map(hand, fn card -> %Card{card | face_down: false} end)
  end

  @doc """
  Nulls out any card which is face down so it's safe to share with a client.
  """
  @spec hide_face_down_cards(t()) :: t()
  def hide_face_down_cards(hand) do
    Enum.map(hand, fn card -> if card.face_down, do: Card.new(nil, nil, true), else: card end)
  end

  def to_string(hand) do
    "[#{Enum.join(hand, ", ")}]"
  end
end
