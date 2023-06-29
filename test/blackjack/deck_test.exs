defmodule BlackjackDeckTest do
  use ExUnit.Case
  doctest Blackjack.Deck

  @max_cards_in_deck 52

  test "new - should shuffle the deck" do
    # Would be exceptionally rare for this to ever fail with 52 cards.
    assert Blackjack.Deck.new() !== Blackjack.Deck.new()
  end

  test "pull_top_card - returns 52 cards" do
    deck = Blackjack.Deck.new()

    Enum.reduce(1..@max_cards_in_deck, deck, fn _element, deck ->
      assert {%Blackjack.Card{value: _, suit: _}, nextDeck} = Blackjack.Deck.pull_top_card(deck)
      nextDeck
    end)
  end

  test "pull_top_card - returns no card on 53rd pull" do
    deck =
      Enum.reduce(1..@max_cards_in_deck, Blackjack.Deck.new(), fn _element, deck ->
        {_, nextDeck} = Blackjack.Deck.pull_top_card(deck)
        nextDeck
      end)

    assert {nil, _} = Blackjack.Deck.pull_top_card(deck)
  end

  test "pull_top_card - returns unique cards" do
    Enum.reduce(1..@max_cards_in_deck, {Blackjack.Deck.new(), MapSet.new()}, fn _,
                                                                                {deck, seenCards} ->
      {card, nextDeck} = Blackjack.Deck.pull_top_card(deck)
      cardKey = "#{card}"

      case MapSet.member?(seenCards, cardKey) do
        false -> {nextDeck, MapSet.put(seenCards, cardKey)}
        true -> raise "Duplicate card found: #{cardKey}"
      end
    end)
  end
end
