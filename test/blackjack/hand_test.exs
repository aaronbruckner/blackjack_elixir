defmodule BlackjackHandTest do
  use ExUnit.Case
  alias Blackjack.Card
  alias Blackjack.Hand

  test "max_safe_score - empty hand is zero points" do
    assert Hand.max_safe_score(Hand.new()) === 0
  end

  test "max_safe_score - under 21, random number cards" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, 9))
      |> Hand.add_card(Card.new(:heart, 2))
      |> Hand.add_card(Card.new(:heart, 5))

    assert Hand.max_safe_score(hand) === 16
  end

  test "max_safe_score - under 21, random number and face cards" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, :jack))
      |> Hand.add_card(Card.new(:heart, 2))
      |> Hand.add_card(Card.new(:heart, 5))

    assert Hand.max_safe_score(hand) === 17
  end

  test "max_safe_score - under 21 with ace counted as 1" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, :jack))
      |> Hand.add_card(Card.new(:heart, 9))
      |> Hand.add_card(Card.new(:heart, :ace))
      |> Hand.add_card(Card.new(:club, :ace))

    assert Hand.max_safe_score(hand) === 21
  end

  test "max_safe_score - over 21 with ace counted as 1" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, :jack))
      |> Hand.add_card(Card.new(:heart, 9))
      |> Hand.add_card(Card.new(:heart, 2))
      |> Hand.add_card(Card.new(:heart, :ace))
      |> Hand.add_card(Card.new(:club, :ace))

    assert Hand.max_safe_score(hand) === 23
  end

  test "max_safe_score - 21 with ace and face card" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, :jack))
      |> Hand.add_card(Card.new(:heart, :ace))

    assert Hand.max_safe_score(hand) === 21
  end

  test "max_safe_score - 21 with ace as 1 and two face cards" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, :jack))
      |> Hand.add_card(Card.new(:heart, :king))
      |> Hand.add_card(Card.new(:heart, :ace))

    assert Hand.max_safe_score(hand) === 21
  end

  test "is_bust - under 21" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, 9))
      |> Hand.add_card(Card.new(:heart, 2))
      |> Hand.add_card(Card.new(:heart, 5))

    assert Hand.is_bust(hand) === false
  end

  test "is_bust - at 21" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, :jack))
      |> Hand.add_card(Card.new(:heart, :ace))

    assert Hand.is_bust(hand) === false
  end

  test "is_bust - over 21" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, :jack))
      |> Hand.add_card(Card.new(:heart, 9))
      |> Hand.add_card(Card.new(:heart, 2))
      |> Hand.add_card(Card.new(:heart, :ace))
      |> Hand.add_card(Card.new(:club, :ace))

    assert Hand.is_bust(hand) === true
  end

  test "hide_face_down_cards - nils out any card which is face down" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, 2, false))
      |> Hand.add_card(Card.new(:heart, 3, true))
      |> Hand.add_card(Card.new(:club, 2, true))
      |> Hand.add_card(Card.new(:club, :jack, false))
      |> Hand.hide_face_down_cards()

    assert [
             %Card{suit: :club, value: :jack, face_down: false},
             %Card{suit: nil, value: nil, face_down: true},
             %Card{suit: nil, value: nil, face_down: true},
             %Card{suit: :heart, value: 2, face_down: false}
           ] = hand
  end

  test "to_string - prints a string representation of the hand" do
    hand =
      Hand.new()
      |> Hand.add_card(Card.new(:heart, 2, false))
      |> Hand.add_card(Card.new(:heart, 3, true))

    assert Hand.to_string(hand) === "[<Face Down>, 2 of hearts]"
  end
end
