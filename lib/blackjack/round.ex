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
          dealer_hand: Hand.t(),
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
      dealer_hand:
        Hand.new()
        |> Hand.add_card(%Card{dealerCard1 | face_down: true})
        |> Hand.add_card(dealerCard2),
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
    current_active_position = find_active_position(round)

    current_active_player =
      get_player_at_position(round, current_active_position)
      |> Player.set_status(:passed)

    if current_active_player.player_id !== player_id do
      {round, [Event.new(:invalid_action, player_id)]}
    else
      round = update_player_at_position(round, current_active_position, current_active_player)

      next_active_position = current_active_position + 1
      next_active_player = get_player_at_position(round, next_active_position)

      {round, events} =
        if next_active_player !== nil do
          # Move active to next player.
          {update_player_at_position(
             round,
             next_active_position,
             Player.set_status(next_active_player, :active)
           ), [Event.new(:new_active_player, next_active_player.player_id)]}
        else
          # All players have been resolved, dealers turn.
          resolve_dealer_actions(round)
        end

      {round,
       [
         %Event{
           type: :action_pass,
           target: player_id,
           score: Hand.max_safe_score(current_active_player.hand)
         }
         | events
       ]}
    end
  end

  @spec action_hit(t(), Player.player_id()) :: {t(), list(Event.t())}
  def action_hit(round, player_id) do
    {card, deck} = Deck.pull_top_card(round.deck)

    current_active_position = find_active_position(round)

    current_active_player =
      get_player_at_position(round, current_active_position)
      |> Player.give_card(card)

    if current_active_player.player_id !== player_id do
      {round, [Event.new(:invalid_action, player_id)]}
    else
      {current_active_player, round, events} =
        if Hand.is_bust(current_active_player.hand) do
          next_active_position = current_active_position + 1

          next_active_player =
            get_player_at_position(round, next_active_position)
            |> Player.set_status(:active)

          {Player.set_status(current_active_player, :busted),
           update_player_at_position(round, next_active_position, next_active_player),
           [Event.new(:new_active_player, next_active_player.player_id)]}
        else
          {current_active_player, round, []}
        end

      round = %Round{
        update_player_at_position(round, current_active_position, current_active_player)
        | deck: deck
      }

      {round,
       [
         %Event{
           Event.new(:action_hit, player_id)
           | card: card,
             score: Hand.max_safe_score(current_active_player.hand)
         }
         | events
       ]}
    end
  end

  @spec resolve_dealer_actions(t()) :: {t(), list(Event.t())}
  defp resolve_dealer_actions(round) do
    dealer_score = Hand.max_safe_score(round.dealer_hand)

    results =
      Enum.map(round.players, fn p ->
        player_score = Hand.max_safe_score(p.hand)

        player_result =
          cond do
            player_score > dealer_score -> :win
            player_score < dealer_score -> :loss
            player_score === dealer_score -> :tie
          end

        %{player_id: p.player_id, result: player_result, score: player_score}
      end)

    {round,
     [
       %Event{Event.new(:round_complete) | round_results: results}
     ]}
  end

  @spec find_active_position(t()) :: integer()
  defp find_active_position(round) do
    Enum.find_index(round.players, fn p -> p.status === :active end)
  end

  @spec get_player_at_position(t(), integer()) :: Player.t() | nil
  defp get_player_at_position(round, index) do
    Enum.at(round.players, index)
  end

  @spec update_player_at_position(t(), integer(), Player.t()) :: t()
  defp update_player_at_position(round, index, player) do
    %Round{round | players: List.replace_at(round.players, index, player)}
  end
end
