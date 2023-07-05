defmodule Blackjack.Event do
  @moduledoc """
  Describes a single kind of event which takes place during a blackjack game.

  Examples: Player 1 passed, Player 2 was delt a 2 of hearts, Player 3 bust.
  """
  alias Blackjack.Event
  alias Blackjack.Card

  @type event_type ::
          :action_pass | :action_hit | :new_active_player | :invalid_action | :round_complete
  @type target :: String.t() | list(String.t()) | nil
  @type player_result :: %{player_id: String.t(), result: :win | :loss | :tie, score: integer()}

  @type t() :: %__MODULE__{
          type: event_type(),
          target: target(),
          score: integer() | nil,
          card: Card.t() | nil,
          round_results: list(player_result()) | nil
        }

  @enforce_keys [:type]
  defstruct [:type, :target, :score, :card, :round_results]

  @spec new(event_type(), target()) :: t()
  def new(type, target \\ nil) do
    %Event{type: type, target: target}
  end
end
