defmodule BlackjackCardTest do
  use ExUnit.Case
  alias Blackjack.Card

  test "new - builds a card" do
    assert Card.new(:heart, 2) === %Card{suit: :heart, value: 2, face_down: false}
  end

  test "new - builds a face down card" do
    assert Card.new(:heart, 2, true) === %Card{suit: :heart, value: 2, face_down: true}
  end

  test "struct - implements to_string for numeric value" do
    assert "#{Card.new(:heart, 2)}" === "2 of hearts"
  end

  test "struct - implements to_string for face value" do
    assert "#{Card.new(:spade, :king)}" === "king of spades"
  end

  test "point_value - returns correct value for numeric cards" do
    Enum.each(2..10, fn value ->
      assert Card.point_value(Card.new(:heart, value)) === value
    end)
  end

  test "point_value - returns correct value for face cards" do
    assert Card.point_value(Card.new(:heart, :jack)) === 10
    assert Card.point_value(Card.new(:heart, :queen)) === 10
    assert Card.point_value(Card.new(:heart, :king)) === 10
  end

  test "point_value - returns minimum value for ace" do
    assert Card.point_value(Card.new(:heart, :ace)) === 1
  end
end
