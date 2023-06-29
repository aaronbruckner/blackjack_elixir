defmodule BlackjackCardTest do
  use ExUnit.Case
  alias Blackjack.Card, as: Card

  test "new - builds a card" do
    assert Card.new(:heart, 2) === %Card{suit: :heart, value: 2}
  end

  test "struct - implements to_string for numeric value" do
    assert "#{%Card{suit: :heart, value: 2}}" === "2 of hearts"
  end

  test "struct - implements to_string for face value" do
    assert "#{%Card{suit: :spade, value: :king}}" === "king of spades"
  end

  test "point_value - returns correct value for numeric cards" do
    Enum.each(2..10, fn value ->
      assert Card.point_value(%Card{suit: :heart, value: value}) === value
    end)
  end

  test "point_value - returns correct value for face cards" do
    assert Card.point_value(%Card{suit: :heart, value: :jack}) === 10
    assert Card.point_value(%Card{suit: :heart, value: :queen}) === 10
    assert Card.point_value(%Card{suit: :heart, value: :king}) === 10
  end

  test "point_value - returns minimum value for ace" do
    assert Card.point_value(%Card{suit: :heart, value: :ace}) === 1
  end
end
