defmodule BlackjackCardTest do
  use ExUnit.Case
  doctest Blackjack.Card

  test "struct - implements to_string for numeric value" do
    assert "#{%Blackjack.Card{suit: :heart, value: 2}}" === "2 of hearts"
  end

  test "struct - implements to_string for face value" do
    assert "#{%Blackjack.Card{suit: :spade, value: :king}}" === "king of spades"
  end
end
