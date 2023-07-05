defmodule Blackjack.Event do
  @moduledoc """
  Describes a single kind of event which takes place during a blackjack game.

  Examples: Player 1 passed, Player 2 was delt a 2 of hearts, Player 3 bust.
  """
  alias Blackjack.Event
  alias Blackjack.Card

  @type event_type :: :action_pass | :action_hit | :new_active_player | :invalid_action

  @type t() :: %__MODULE__{
          type: event_type(),
          target: String.t() | nil,
          score: integer() | nil,
          card: Card.t() | nil
        }

  @enforce_keys [:type]
  defstruct [:type, :target, :score, :card]

  @spec new(event_type(), String.t() | nil) :: t()
  def new(type, target \\ nil) do
    %Event{type: type, target: target}
  end
end
