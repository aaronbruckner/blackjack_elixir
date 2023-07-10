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

  @typedoc """
  Describes the state of a single card. If the card is face down, it's suit and value shouldn't
  be known to other players.
  """
  @type t() :: %__MODULE__{
          suit: suit(),
          value: value(),
          face_down: boolean()
        }

  @enforce_keys [:suit, :value]
  defstruct [:suit, :value, face_down: false]

  @spec new(suit() | nil, value() | nil, boolean()) :: t()
  def new(suit, value, face_down \\ false),
    do: %Card{suit: suit, value: value, face_down: face_down}

  @doc """
  Returns the numeric value for a card. Aces will always return a value of 1.
  """
  @spec point_value(t()) :: integer()
  def point_value(card) do
    cond do
      card.face_down -> 0
      is_number(card.value) -> card.value
      card.value === :ace -> 1
      true -> 10
    end
  end
end

defimpl String.Chars, for: Blackjack.Card do
  @spec to_string(Blackjack.Card.t()) :: String.t()
  def to_string(card) do
    if card.face_down do
      "<Face Down>"
    else
      "#{card.value} of #{card.suit}s"
    end
  end
end
