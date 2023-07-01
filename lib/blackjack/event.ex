defmodule Blackjack.Event do
  @moduledoc """
  Describes a single kind of event which takes place during a blackjack game.

  Examples: Player 1 passed, Player 2 was delt a 2 of hearts, Player 3 bust.
  """

  @type event_type :: :action_pass

  @type t() :: %__MODULE__{
          type: event_type(),
          target: String.t(),
          score: integer()
        }

  @enforce_keys [:type]
  defstruct [:type, :target, :score]
end
