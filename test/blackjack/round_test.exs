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

    {round, _events} = Round.start_new_round(player_ids)

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

    {round, _events} = Round.start_new_round(player_ids)

    assert %Round{
             players: [%Player{hand: [%Card{}, %Card{}]}, %Player{hand: [%Card{}, %Card{}]}],
             dealer_hand: [%Card{}, %Card{}]
           } = round
  end

  test "start_new_round - deals cards from the deck correctly" do
    player_ids = ["p1", "p2"]

    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    assert %Round{
             players: [
               %Player{hand: [%Card{value: 3}, %Card{value: 2}]},
               %Player{hand: [%Card{value: 5}, %Card{value: 4}]}
             ],
             dealer_hand: [%Card{value: 7, face_down: false}, %Card{value: 6, face_down: true}]
           } = round
  end

  test "start_new_round - generates events for all initial cards delt on start" do
    player_ids = ["p1", "p2"]

    {_round, events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    assert [
             %Event{card: %Card{suit: :club, value: 2}, score: 2},
             %Event{card: %Card{suit: :club, value: 3}, score: 5}
           ] = Enum.filter(events, &(&1.type === :card_dealt and &1.target === "p1"))

    assert [
             %Event{card: %Card{suit: :club, value: 4}, score: 4},
             %Event{card: %Card{suit: :club, value: 5}, score: 9}
           ] = Enum.filter(events, &(&1.type === :card_dealt and &1.target === "p2"))

    assert [
             %Event{card: %Card{suit: nil, value: nil}, score: 0},
             %Event{card: %Card{suit: :club, value: 7}, score: 7}
           ] = Enum.filter(events, &(&1.type === :card_dealt and &1.target === ":dealer"))
  end

  test "start_new_round - sets player statuses correctly" do
    player_ids = ["p1", "p2"]

    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    assert %Round{
             players: [
               %Player{status: :active},
               %Player{status: :waiting}
             ]
           } = round
  end

  test "action_pass - moves to the next player" do
    player_ids = ["p1", "p2"]
    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, events} = Round.action_pass(round, "p1")

    assert %Event{target: "p1", score: 5} = Enum.find(events, &(&1.type === :action_pass))
    assert %Event{target: "p2"} = Enum.find(events, &(&1.type === :new_active_player))
    assert nil === Enum.find(events, &(&1.type === :invalid_action))

    assert %Round{
             players: [
               %Player{status: :passed},
               %Player{status: :active}
             ]
           } = round
  end

  test "action_pass - non-active player taking invalid action is ignored" do
    player_ids = ["p1", "p2"]
    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, events} = Round.action_pass(round, "p2")

    assert nil === Enum.find(events, &(&1.type === :action_pass))
    assert nil === Enum.find(events, &(&1.type === :new_active_player))
    assert %Event{target: "p2"} = Enum.find(events, &(&1.type === :invalid_action))

    assert %Round{
             players: [
               %Player{status: :active},
               %Player{status: :waiting}
             ]
           } = round
  end

  test "action_pass - able to pass two players in a row" do
    player_ids = ["p1", "p2", "p3"]
    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, _events} = Round.action_pass(round, "p1")
    {round, events} = Round.action_pass(round, "p2")

    assert %Event{target: "p2", score: 9} = Enum.find(events, &(&1.type === :action_pass))
    assert %Event{target: "p3"} = Enum.find(events, &(&1.type === :new_active_player))
    assert nil === Enum.find(events, &(&1.type === :invalid_action))

    assert %Round{
             players: [
               %Player{status: :passed},
               %Player{status: :passed},
               %Player{status: :active}
             ]
           } = round
  end

  test "action_hit - provides player a card, not bust" do
    player_ids = ["p1", "p2"]
    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, events} = Round.action_hit(round, "p1")

    assert %Event{target: "p1", card: %Card{suit: :club, value: 8}, score: 13} =
             Enum.find(events, &(&1.type === :action_hit))

    assert nil === Enum.find(events, &(&1.type === :new_active_player))
    assert nil === Enum.find(events, &(&1.type === :invalid_action))

    assert %Round{
             players: [
               %Player{
                 status: :active,
                 hand: [%Card{suit: :club, value: 8}, %Card{value: 3}, %Card{value: 2}]
               },
               %Player{status: :waiting}
             ]
           } = round
  end

  test "action_hit - returns multiple cards, player goes bust" do
    player_ids = ["p1", "p2"]
    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, _events} = Round.action_hit(round, "p1")
    {round, events} = Round.action_hit(round, "p1")

    assert %Event{target: "p1", card: %Card{suit: :club, value: 9}, score: 22} =
             Enum.find(events, &(&1.type === :action_hit))

    assert %Event{target: "p2"} = Enum.find(events, &(&1.type === :new_active_player))
    assert nil === Enum.find(events, &(&1.type === :invalid_action))

    assert %Round{
             players: [
               %Player{
                 status: :busted,
                 hand: [
                   %Card{suit: :club, value: 9},
                   %Card{value: 8},
                   %Card{value: 3},
                   %Card{value: 2}
                 ]
               },
               %Player{status: :active}
             ]
           } = round
  end

  test "action_hit - second player can take a hit" do
    player_ids = ["p1", "p2"]
    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)

    {round, _events} = Round.action_pass(round, "p1")
    {round, events} = Round.action_hit(round, "p2")

    assert %Event{target: "p2", card: %Card{suit: :club, value: 8}, score: 17} =
             Enum.find(events, &(&1.type === :action_hit))

    assert nil === Enum.find(events, &(&1.type === :invalid_action))

    assert %Round{
             players: [
               %Player{
                 status: :passed
               },
               %Player{
                 status: :active,
                 hand: [%Card{suit: :club, value: 8}, %Card{value: 5}, %Card{value: 4}]
               }
             ]
           } = round
  end

  test "action_hit - non-active player taking out of order action is ignored" do
    player_ids = ["p1", "p2"]
    {round, _events} = Round.start_new_round(player_ids, deck: @ordered_deck)
    deck = round.deck

    {round, events} = Round.action_hit(round, "p2")

    assert nil === Enum.find(events, &(&1.type === :action_hit))
    assert nil === Enum.find(events, &(&1.type === :new_active_player))
    assert %Event{target: "p2"} = Enum.find(events, &(&1.type === :invalid_action))

    assert %Round{
             players: [
               %Player{
                 status: :active,
                 hand: [%Card{value: 3}, %Card{value: 2}]
               },
               %Player{status: :waiting}
             ],
             deck: ^deck
           } = round
  end

  test "action_pass last player - dealer wins, no cards to draw" do
    deck =
      Deck.new([
        Card.new(:club, 10),
        Card.new(:club, 2),
        Card.new(:heart, 10),
        Card.new(:heart, 7),
        Card.new(:heart, :king)
      ])

    player_ids = ["p1"]
    {round, _events} = Round.start_new_round(player_ids, deck: deck)

    {round, events} = Round.action_pass(round, "p1")

    assert %Event{
             round_results: [%{player_id: "p1", result: :loss, score: 12}],
             dealer_hand: [%Card{value: 7, suit: :heart}, %Card{value: 10, suit: :heart}]
           } = Enum.find(events, &(&1.type === :round_complete))

    assert %Round{
             players: [
               %Player{status: :passed}
             ],
             dealer_hand: [%Card{value: 7, suit: :heart}, %Card{value: 10, suit: :heart}]
           } = round
  end

  test "action_pass last player - mix if wins, losses, and ties, no cards to draw" do
    deck =
      Deck.new([
        Card.new(:club, 10),
        Card.new(:club, :ace),
        Card.new(:spade, 10),
        Card.new(:spade, 7),
        Card.new(:diamond, 10),
        Card.new(:diamond, 6),
        Card.new(:heart, 10),
        Card.new(:heart, 7),
        Card.new(:heart, :king)
      ])

    player_ids = ["p1", "p2", "p3"]
    {round, _events} = Round.start_new_round(player_ids, deck: deck)

    {round, _events} = Round.action_pass(round, "p1")
    {round, _events} = Round.action_pass(round, "p2")
    {round, events} = Round.action_pass(round, "p3")

    assert %Event{
             round_results: [
               %{player_id: "p1", result: :win, score: 21},
               %{player_id: "p2", result: :tie, score: 17},
               %{player_id: "p3", result: :loss, score: 16}
             ],
             dealer_hand: [%Card{value: 7, suit: :heart}, %Card{value: 10, suit: :heart}]
           } = Enum.find(events, &(&1.type === :round_complete))

    assert %Round{
             players: [
               %Player{status: :passed},
               %Player{status: :passed},
               %Player{status: :passed}
             ],
             dealer_hand: [%Card{value: 7, suit: :heart}, %Card{value: 10, suit: :heart}]
           } = round
  end

  test "action_pass last player - dealer must draw cards" do
    deck =
      Deck.new([
        Card.new(:club, 10),
        Card.new(:club, 2),
        Card.new(:heart, 8),
        Card.new(:heart, 2),
        Card.new(:heart, 6),
        Card.new(:heart, :ace),
        Card.new(:heart, :king)
      ])

    player_ids = ["p1"]
    {round, _events} = Round.start_new_round(player_ids, deck: deck)

    {round, events} = Round.action_pass(round, "p1")

    assert %Event{
             round_results: [%{player_id: "p1", result: :loss, score: 12}],
             dealer_hand: [
               %Card{value: :ace, suit: :heart},
               %Card{value: 6, suit: :heart},
               %Card{value: 2, suit: :heart},
               %Card{value: 8, suit: :heart}
             ]
           } = Enum.find(events, &(&1.type === :round_complete))

    assert %Round{
             players: [
               %Player{status: :passed}
             ],
             dealer_hand: [
               %Card{value: :ace, suit: :heart},
               %Card{value: 6, suit: :heart},
               %Card{value: 2, suit: :heart},
               %Card{value: 8, suit: :heart}
             ],
             deck: [%Card{value: :king, suit: :heart}]
           } = round
  end

  test "action_pass last player - ace prevents drawing additional cards" do
    deck =
      Deck.new([
        Card.new(:club, 10),
        Card.new(:club, 2),
        Card.new(:heart, 6),
        Card.new(:heart, :ace),
        Card.new(:heart, :king)
      ])

    player_ids = ["p1"]
    {round, _events} = Round.start_new_round(player_ids, deck: deck)

    {round, events} = Round.action_pass(round, "p1")

    assert %Event{
             round_results: [%{player_id: "p1", result: :loss, score: 12}],
             dealer_hand: [
               %Card{value: :ace, suit: :heart},
               %Card{value: 6, suit: :heart}
             ]
           } = Enum.find(events, &(&1.type === :round_complete))

    assert %Round{
             players: [
               %Player{status: :passed}
             ],
             dealer_hand: [
               %Card{value: :ace, suit: :heart},
               %Card{value: 6, suit: :heart}
             ],
             deck: [%Card{value: :king, suit: :heart}]
           } = round
  end

  test "action_hit last player - bust players cannot win" do
    deck =
      Deck.new([
        Card.new(:club, 10),
        Card.new(:club, :jack),
        Card.new(:heart, 10),
        Card.new(:heart, 6),
        Card.new(:club, 2),
        Card.new(:heart, :king),
        Card.new(:heart, :ace)
      ])

    player_ids = ["p1"]
    {round, _events} = Round.start_new_round(player_ids, deck: deck)

    {round, events} = Round.action_hit(round, "p1")

    assert %Event{
             round_results: [%{player_id: "p1", result: :loss, score: 22}],
             dealer_hand: [
               %Card{value: :king, suit: :heart},
               %Card{value: 6, suit: :heart},
               %Card{value: 10, suit: :heart}
             ]
           } = Enum.find(events, &(&1.type === :round_complete))

    assert %Round{
             players: [
               %Player{status: :busted}
             ],
             dealer_hand: [
               %Card{value: :king, suit: :heart},
               %Card{value: 6, suit: :heart},
               %Card{value: 10, suit: :heart}
             ],
             deck: [%Card{value: :ace, suit: :heart}]
           } = round
  end

  test "Dealer goes bust" do
    deck =
      Deck.new([
        Card.new(:club, 10),
        Card.new(:club, :jack),
        Card.new(:heart, 10),
        Card.new(:heart, 6),
        Card.new(:heart, :king),
        Card.new(:heart, :ace)
      ])

    player_ids = ["p1"]
    {round, _events} = Round.start_new_round(player_ids, deck: deck)

    {round, events} = Round.action_pass(round, "p1")

    assert %Event{
             round_results: [%{player_id: "p1", result: :win, score: 20}],
             dealer_hand: [
               %Card{value: :king, suit: :heart},
               %Card{value: 6, suit: :heart},
               %Card{value: 10, suit: :heart}
             ]
           } = Enum.find(events, &(&1.type === :round_complete))

    assert %Round{
             players: [
               %Player{status: :passed}
             ],
             dealer_hand: [
               %Card{value: :king, suit: :heart},
               %Card{value: 6, suit: :heart},
               %Card{value: 10, suit: :heart}
             ],
             deck: [%Card{value: :ace, suit: :heart}]
           } = round
  end

  test "make_client_safe - return santized version of the round" do
    deck =
      Deck.new([
        Card.new(:club, 10),
        Card.new(:club, :jack),
        Card.new(:heart, 10),
        Card.new(:heart, 6),
        Card.new(:heart, :king),
        Card.new(:heart, :ace)
      ])

    player_ids = ["p1"]

    {round, _events} = Round.start_new_round(player_ids, deck: deck)

    assert %Round{
             players: [
               %Player{
                 player_id: "p1",
                 hand: [%Card{suit: :club, value: :jack}, %Card{suit: :club, value: 10}],
                 status: :active
               }
             ],
             dealer_hand: [
               %Card{value: 6, suit: :heart},
               %Card{value: nil, suit: nil, face_down: true}
             ],
             deck: []
           } === Round.make_client_safe(round)
  end

  test "get_active_player_id - returns ID of active player" do
    player_ids = ["p1", "p2", "p3"]

    {round, _events} = Round.start_new_round(player_ids)

    {round, _events} = Round.action_pass(round, "p1")

    assert Round.get_active_player_id(round) === "p2"
  end

  test "get_active_player_id - returns nil if no player is active" do
    player_ids = ["p1"]

    {round, _events} = Round.start_new_round(player_ids)

    {round, _events} = Round.action_pass(round, "p1")

    assert Round.get_active_player_id(round) === nil
  end
end
