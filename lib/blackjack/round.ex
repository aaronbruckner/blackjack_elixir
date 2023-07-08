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
          deck: Deck.t()
        }

  @enforce_keys [:players, :dealer_hand, :deck]
  defstruct [:players, :dealer_hand, :deck]

  @dealer_score_limit 17
  @dealer_id ":dealer"

  @doc """
  Starts a new round of blackjack with the list of provided players.
  Players are automatically delt 2 cards from the deck and the dealer is
  delt a face down, face up card.

  If a deck isn't provided, a 52 card shuffled deck will be used.
  """
  @spec start_new_round(list(Player.player_id()), keyword()) :: {t(), list(Event.t())}
  def start_new_round(player_ids, options \\ []) do
    deck = Keyword.get(options, :deck, Deck.new())

    {deck, players, events} =
      Enum.reduce(
        player_ids,
        {deck, [], []},
        fn player_id, {deck, players, events} ->
          {card1, deck} = Deck.pull_top_card(deck)
          {card2, deck} = Deck.pull_top_card(deck)

          player =
            Player.new(player_id)
            |> Player.give_card(card1)
            |> Player.set_status(if players === [], do: :active, else: :waiting)

          dealt_event_1 = %Event{
            Event.new(:card_dealt, player_id)
            | card: card1,
              score: Hand.max_safe_score(player.hand)
          }

          player = Player.give_card(player, card2)

          dealt_event_2 = %Event{
            Event.new(:card_dealt, player_id)
            | card: card2,
              score: Hand.max_safe_score(player.hand)
          }

          {deck, players ++ [player], events ++ [dealt_event_1, dealt_event_2]}
        end
      )

    {dealerCard1, deck} = Deck.pull_top_card(deck, true)
    {dealerCard2, deck} = Deck.pull_top_card(deck)

    dealer_hand =
      Hand.new()
      |> Hand.add_card(dealerCard1)
      |> Hand.add_card(dealerCard2)

    events =
      events ++
        [
          %Event{Event.new(:card_dealt, @dealer_id) | card: Card.new(nil, nil, true), score: 0},
          %Event{
            Event.new(:card_dealt, @dealer_id)
            | card: dealerCard2,
              score: Hand.max_safe_score(dealer_hand)
          }
        ]

    {%Round{
       players: players,
       dealer_hand: dealer_hand,
       deck: deck
     }, events}
  end

  @doc """
  Allows a specific player to issue a "pass" action indicating they want no additional cards.
  Only the active player can issue this command. The resulting round state and events which
  ocurred due to this action are returned.
  """
  @spec action_pass(t(), Player.player_id()) :: {t(), list(Event.t())}
  def action_pass(round, player_id) do
    current_active_position = find_active_position(round)

    if get_player_id_at_position(round, current_active_position) !== player_id do
      {round, [Event.new(:invalid_action, player_id)]}
    else
      round = set_player_status_at_position(round, current_active_position, :passed)

      next_active_position = current_active_position + 1
      is_last_player = length(round.players) === next_active_position

      {round, events} =
        if is_last_player do
          # All players have been resolved, dealers turn.
          resolve_dealer_actions(round)
        else
          # Move active to next player.
          {set_player_status_at_position(
             round,
             next_active_position,
             :active
           ),
           [Event.new(:new_active_player, get_player_id_at_position(round, next_active_position))]}
        end

      {round,
       [
         %Event{
           type: :action_pass,
           target: player_id,
           score: get_player_score_at_position(round, current_active_position)
         }
         | events
       ]}
    end
  end

  @spec action_hit(t(), Player.player_id()) :: {t(), list(Event.t())}
  def action_hit(round, player_id) do
    current_active_position = find_active_position(round)

    if get_player_id_at_position(round, current_active_position) !== player_id do
      {round, [Event.new(:invalid_action, player_id)]}
    else
      {round, card} = pull_card_from_deck(round)
      round = pass_card_to_position(round, current_active_position, card)
      has_busted = is_player_bust_at_position?(round, current_active_position)

      round =
        if has_busted do
          set_player_status_at_position(round, current_active_position, :busted)
        else
          round
        end

      next_active_position = current_active_position + 1
      is_last_player = length(round.players) === next_active_position

      {round, events} =
        cond do
          has_busted and is_last_player ->
            resolve_dealer_actions(round)

          has_busted ->
            {set_player_status_at_position(round, next_active_position, :active),
             [
               Event.new(
                 :new_active_player,
                 get_player_id_at_position(round, next_active_position)
               )
             ]}

          true ->
            {round, []}
        end

      {round,
       [
         %Event{
           Event.new(:action_hit, player_id)
           | card: card,
             score: get_player_score_at_position(round, current_active_position)
         }
         | events
       ]}
    end
  end

  @doc """
  Returns a view of the round which has been sanitized and is safe to show to clients.
  """
  @spec make_client_safe(t()) :: t()
  def make_client_safe(round) do
    %Round{
      players: round.players,
      dealer_hand: Hand.hide_face_down_cards(round.dealer_hand),
      deck: Deck.new([])
    }
  end

  @doc """
  Returns the ID of the active player. If no player is active, nil is returned.
  """
  @spec get_active_player_id(t()) :: Player.player_id() | nil
  def get_active_player_id(round) do
    case Enum.find(round.players, &(&1.status === :active)) do
      nil -> nil
      p -> p.player_id
    end
  end

  @spec get_player_score_at_position(t(), integer()) :: integer()
  defp get_player_score_at_position(round, position) do
    Hand.max_safe_score(get_player_at_position(round, position).hand)
  end

  @spec is_player_bust_at_position?(t(), integer()) :: boolean()
  defp is_player_bust_at_position?(round, position) do
    Hand.is_bust(get_player_at_position(round, position).hand)
  end

  @spec get_player_id_at_position(t(), integer()) :: Player.player_id()
  defp get_player_id_at_position(round, position) do
    get_player_at_position(round, position).player_id
  end

  @spec set_player_status_at_position(t(), integer(), Player.status()) :: t()
  defp set_player_status_at_position(round, position, status) do
    player =
      get_player_at_position(round, position)
      |> Player.set_status(status)

    update_player_at_position(round, position, player)
  end

  @spec pass_card_to_position(t(), integer(), Card.t()) :: t()
  defp pass_card_to_position(round, position, card) do
    player =
      get_player_at_position(round, position)
      |> Player.give_card(card)

    update_player_at_position(round, position, player)
  end

  @spec pull_card_from_deck(t()) :: {t(), Card.t()}
  defp pull_card_from_deck(round) do
    {card, deck} = Deck.pull_top_card(round.deck)
    {%Round{round | deck: deck}, card}
  end

  defp reveal_dealer_cards(round) do
    %Round{round | dealer_hand: Hand.show_cards(round.dealer_hand)}
  end

  @spec resolve_dealer_actions(t()) :: {t(), list(Event.t())}
  defp resolve_dealer_actions(round) do
    # Allows the dealer to resolve their draw steps and determine winners, losers, and ties.
    round = reveal_dealer_cards(round)
    {deck, dealer_hand} = draw_dealer_cards(round.deck, round.dealer_hand)
    dealer_score = Hand.max_safe_score(dealer_hand)
    dealer_bust = Hand.is_bust(dealer_hand)

    results =
      Enum.map(round.players, fn p ->
        player_score = Hand.max_safe_score(p.hand)

        player_result =
          cond do
            Hand.is_bust(p.hand) -> :loss
            dealer_bust or player_score > dealer_score -> :win
            player_score < dealer_score -> :loss
            player_score === dealer_score -> :tie
          end

        %{player_id: p.player_id, result: player_result, score: player_score}
      end)

    {%Round{round | dealer_hand: dealer_hand, deck: deck},
     [
       %Event{Event.new(:round_complete) | round_results: results, dealer_hand: dealer_hand}
     ]}
  end

  @spec draw_dealer_cards(Deck.t(), Hand.t()) :: {Deck.t(), Hand.t()}
  defp draw_dealer_cards(deck, dealer_hand) do
    if Hand.max_safe_score(dealer_hand) < @dealer_score_limit do
      {card, deck} = Deck.pull_top_card(deck)
      draw_dealer_cards(deck, Hand.add_card(dealer_hand, card))
    else
      {deck, dealer_hand}
    end
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
