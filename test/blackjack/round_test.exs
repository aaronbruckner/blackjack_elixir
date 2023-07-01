defmodule BlackjackRoundTest do
  use ExUnit.Case

  alias Blackjack.Card
  alias Blackjack.Deck
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
    player_ids = ["p3", "p2", "p1"]

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
    player_ids = ["p2", "p1"]

    round = Round.start_new_round(player_ids)

    assert %Round{
             players: [%Player{hand: [%Card{}, %Card{}]}, %Player{hand: [%Card{}, %Card{}]}],
             dealer_hand: [%Card{}, %Card{}]
           } = round
  end

  test "start_new_round - deals cards from the deck correctly" do
    player_ids = ["p2", "p1"]

    round = Round.start_new_round(player_ids, deck: @ordered_deck)

    assert %Round{
             players: [
               %Player{hand: [%Card{value: 5}, %Card{value: 4}]},
               %Player{hand: [%Card{value: 3}, %Card{value: 2}]}
             ],
             dealer_hand: [%Card{value: 7, face_down: false}, %Card{value: 6, face_down: true}]
           } = round
  end
end
