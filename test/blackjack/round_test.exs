defmodule BlackjackRoundTest do
  use ExUnit.Case

  alias Blackjack.Card
  alias Blackjack.Deck
  alias Blackjack.Event
  alias Blackjack.Player
  alias Blackjack.Round

  @ordered_deck Deck.new([
                  Card.new(:club, 2),
                  Card.new(:club, 3),
                  Card.new(:club, 4),
                  Card.new(:club, 5),
                  Card.new(:club, 6),
                  Card.new(:club, 7),
                  Card.new(:club, 8),
                  Card.new(:club, 9),
                  Card.new(:club, 10)
                ])

  test "start_new_round - creates players" do
    player_ids = ["p1", "p2", "p3"]

    round = Round.start_new_round(player_ids)

    assert %Round{
             players: [
               %Player{player_id: "p1"},
               %Player{player_id: "p2"},
               %Player{player_id: "p3"}
             ]
           } = round
  end

  test "start_new_round - deals 2 cards to each player and dealer" do
    player_ids = ["p1", "p2"]

    round = Round.start_new_round(player_ids)

    assert %Round{
             players: [%Player{hand: [%Card{}, %Card{}]}, %Player{hand: [%Card{}, %Card{}]}],
             dealer_hand: [%Card{}, %Card{}]
           } = round
  end

  test "start_new_round - deals cards from the deck correctly" do
    player_ids = ["p1", "p2"]

    round = Round.start_new_round(player_ids, deck: @ordered_deck)

    assert %Round{
             players: [
               %Player{hand: [%Card{value: 3}, %Card{value: 2}]},
               %Player{hand: [%Card{value: 5}, %Card{value: 4}]}
             ],
             dealer_hand: [%Card{value: 7, face_down: false}, %Card{value: 6, face_down: true}]
           } = round
  end

  test "start_new_round - sets correct number of players" do
    player_ids = ["p1", "p2", "p3"]

    round = Round.start_new_round(player_ids, deck: @ordered_deck)

    assert %Round{total_players: 3} = round
  end

  test "start_new_round - sets player statuses correctly" do
    player_ids = ["p1", "p2"]

    round = Round.start_new_round(player_ids, deck: @ordered_deck)

    assert %Round{
             players: [
               %Player{status: :active},
               %Player{status: :waiting}
             ]
           } = round
  end

  test "action_pass - moves to the next player" do
    player_ids = ["p1", "p2"]
    round = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, events} = Round.action_pass(round, "p1")

    assert %Event{target: "p1", score: 5} = Enum.find(events, &(&1.type === :action_pass))

    assert %Round{
             players: [
               %Player{status: :passed},
               %Player{status: :active}
             ]
           } = round
  end

  test "action_pass - able to pass two players in a row" do
    player_ids = ["p1", "p2", "p3"]
    round = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, _events} = Round.action_pass(round, "p1")
    {round, events} = Round.action_pass(round, "p2")

    assert %Event{target: "p2", score: 9} = Enum.find(events, &(&1.type === :action_pass))

    assert %Round{
             players: [
               %Player{status: :passed},
               %Player{status: :passed},
               %Player{status: :active}
             ]
           } = round
  end
end