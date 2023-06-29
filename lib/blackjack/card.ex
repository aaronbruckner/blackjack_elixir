defmodule Blackjack.Card do
  alias Blackjack.Card
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

  @spec new(suit(), value()) :: t()
  def new(suit, value), do: %Card{suit: suit, value: value}

  @doc """
  Returns the numeric value for a card. Aces will always return a value of 1.
  """
  @spec point_value(t()) :: integer()
  def point_value(card) do
    case card.value do
      x when is_number(x) -> x
      :ace -> 1
      _ -> 10
    end
  end
end

defimpl String.Chars, for: Blackjack.Card do
  @spec to_string(Blackjack.Card.t()) :: String.t()
  def to_string(card) do
    "#{card.value} of #{card.suit}s"
  end
end
