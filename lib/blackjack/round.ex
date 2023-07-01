defmodule Blackjack.Round do
  @moduledoc """
  Wraps and manages all logic needed to play a single round of blackjack.

  Provides functionality for adding players, dealing cards, resolving the active
  player, and determining a winner.
  """

  alias Blackjack.Card
  alias Blackjack.Deck
  alias Blackjack.Round
  alias Blackjack.Player

  @type t() :: %__MODULE__{
    players: list(Player.t()),
    dealer_hand: Deck.t(),
    deck: Deck.t(),
    total_players: integer(),
  }

  @enforce_keys [:players, :dealer_hand, :deck, :total_players]
  defstruct [:players, :dealer_hand, :deck, :total_players]

  @doc """
  Starts a new round of blackjack with the list of provided players.
  Players are automatically delt 2 cards from the deck and the dealer is
  delt a face down, face up card.

  If a deck isn't provided, a 52 card shuffled deck will be used.
  """
  @spec start_new_round(list(Player.player_id()), keyword()) :: t()
  def start_new_round(player_ids, options \\ []) do
    deck = Keyword.get(options, :deck, Deck.new())

    {deck, players} =
      Enum.reduce(
        player_ids,
        {deck, []},
        fn player_id, {deck, players} ->
          {card1, deck} = Deck.pull_top_card(deck)
          {card2, deck} = Deck.pull_top_card(deck)

          player =
            Player.new(player_id)
            |> Player.give_card(card1)
            |> Player.give_card(card2)

          {deck, players ++ [player]}
        end
      )

    {dealerCard1, deck} = Deck.pull_top_card(deck)
    {dealerCard2, deck} = Deck.pull_top_card(deck)

    %Round{
      players: players,
      dealer_hand: [dealerCard2, %Card{dealerCard1 | face_down: true}],
      deck: deck,
      total_players: length(players)
    }
  end
end
