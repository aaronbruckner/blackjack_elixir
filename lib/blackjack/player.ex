defmodule Blackjack.Player do
  alias Blackjack.Card
  alias Blackjack.Player
  alias Blackjack.Hand

  @type player_id() :: String.t()
  @type t() :: %__MODULE__{
          player_id: player_id(),
          hand: Hand.t()
        }

  @enforce_keys [:player_id, :hand]
  defstruct [:player_id, :hand]

  @spec new(player_id()) :: t()
  def new(player_id) do
    %Player{player_id: player_id, hand: Hand.new()}
  end

  @spec give_card(t(), Card.t()) :: t()
  def give_card(player, card) do
    %{player | hand: Hand.add_card(player.hand, card)}
  end
end
