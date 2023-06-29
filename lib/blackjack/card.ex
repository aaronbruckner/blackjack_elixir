defmodule Blackjack.Card do
  @typedoc """
  Defines the four allowed suit types a card may be.
  """
  @type suit() :: :heart | :diamond | :spade | :club

  @typedoc """
  Defines the allowed value of a card (2, 10, Jack, Ace, etc)
  """
  @type value() :: 2..10 | :jack | :queen | :king | :ace

  @type t() :: %__MODULE__{
          suit: suit(),
          value: value()
        }

  @enforce_keys [:suit, :value]
  defstruct [:suit, :value]
end

defimpl String.Chars, for: Blackjack.Card do
  @spec to_string(Blackjack.Card.t()) :: String.t()
  def to_string(card) do
    "#{card.value} of #{card.suit}s"
  end
end
