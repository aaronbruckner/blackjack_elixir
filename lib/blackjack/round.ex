defmodule Blackjack.Round do
  @moduledoc """
  Wraps and manages all logic needed to play a single round of blackjack.

  Provides functionality for adding players, dealing cards, resolving the active
  player, and determining a winner.
  """

  alias Blackjack.Card
  alias Blackjack.Deck
  alias Blackjack.Event
  alias Blackjack.Hand
  alias Blackjack.Round
  alias Blackjack.Player

  @type t() :: %__MODULE__{
          players: list(Player.t()),
          dealer_hand: Deck.t(),
          deck: Deck.t(),
          total_players: integer()
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
            |> Player.set_status(if players === [], do: :active, else: :waiting)

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

  @doc """
  Allows a specific player to issue a "pass" action indicating they want no additional cards.
  Only the active player can issue this command. The resulting round state and events which
  ocurred due to this action are returned.
  """
  @spec action_pass(t(), Player.player_id()) :: {t(), list(Event.t())}
  def action_pass(round, player_id) do
    # TODO: Handle edge case where provided player isn't active player
    {active_index, active_player} = find_player_and_index(round, player_id)

    round =
      round
      |> update_player_status_at_position(active_index, :passed)
      |> update_player_status_at_position(active_index + 1, :active)

    new_active_player = find_active_player(round)

    {round,
     [
       %Event{
         type: :action_pass,
         target: player_id,
         score: Hand.max_safe_score(active_player.hand)
       },
       Event.new(:new_active_player, new_active_player.player_id)
     ]}
  end

  @spec action_hit(t(), Player.player_id()) :: {t(), list(Event.t())}
  def action_hit(round, player_id) do
    # TODO: Handle edge case where provided player isn't active player
    {active_index, _active_player} = find_player_and_index(round, player_id)

    {card, deck} = Deck.pull_top_card(round.deck)
    {round, active_player} = pass_card_to_position(round, active_index, card)

    round =
      if active_player.status === :busted do
        update_player_status_at_position(round, active_index + 1, :active)
      else
        round
      end

    {%Round{round | deck: deck},
     [
       %Event{
         Event.new(:action_hit, player_id)
         | card: card,
           score: Hand.max_safe_score(active_player.hand)
       }
     ]}
  end

  @spec find_active_player(t()) :: Player.t()
  defp find_active_player(round) do
    Enum.find(round.players, fn p -> p.status === :active end)
  end

  @spec find_player_and_index(t(), Player.player_id()) :: {integer(), Player.t()}
  defp find_player_and_index(round, player_id) do
    index = Enum.find_index(round.players, fn p -> p.player_id === player_id end)
    {index, Enum.at(round.players, index)}
  end

  @spec update_player_status_at_position(t(), integer(), Player.status()) :: t()
  defp update_player_status_at_position(round, index, status) do
    player = Enum.at(round.players, index)

    %Round{
      round
      | players: List.replace_at(round.players, index, Player.set_status(player, status))
    }
  end

  @spec pass_card_to_position(t(), integer(), Card.t()) :: {t(), Player.t()}
  defp pass_card_to_position(round, index, card) do
    player =
      Enum.fetch!(round.players, index)
      |> Player.give_card(card)

    player =
      if Hand.is_bust(player.hand) do
        Player.set_status(player, :busted)
      else
        player
      end

    {%Round{round | players: List.replace_at(round.players, index, player)}, player}
  end
end
