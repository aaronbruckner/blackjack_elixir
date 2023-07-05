defmodule BlackjackDeckTest do
  use ExUnit.Case

  alias Blackjack.Card
  alias Blackjack.Deck

  @max_cards_in_deck 52

  test "new - should shuffle the deck" do
    # Would be exceptionally rare for this to ever fail with 52 cards.
    assert Deck.new() !== Deck.new()
  end

  test "new - with specific cards" do
    card1 = Card.new(:heart, 2)
    card2 = Card.new(:heart, 3)
    card3 = Card.new(:heart, 4)

    deck = Deck.new([card1, card2, card3])

    assert {^card1, deck} = Deck.pull_top_card(deck)
    assert {^card2, deck} = Deck.pull_top_card(deck)
    assert {^card3, _deck} = Deck.pull_top_card(deck)
  end

  test "pull_top_card - returns 52 cards" do
    deck = Deck.new()

    Enum.reduce(1..@max_cards_in_deck, deck, fn _element, deck ->
      assert {_, nextDeck} = Deck.pull_top_card(deck)
      nextDeck
    end)
  end

  test "pull_top_card - returns no card on 53rd pull" do
    deck =
      Enum.reduce(1..@max_cards_in_deck, Deck.new(), fn _element, deck ->
        {_, nextDeck} = Deck.pull_top_card(deck)
        nextDeck
      end)

    assert {nil, _} = Deck.pull_top_card(deck)
  end

  test "pull_top_card - returns unique cards" do
    Enum.reduce(1..@max_cards_in_deck, {Deck.new(), MapSet.new()}, fn _, {deck, seenCards} ->
      {card, nextDeck} = Deck.pull_top_card(deck)
      cardKey = "#{card}"

      case MapSet.member?(seenCards, cardKey) do
        false -> {nextDeck, MapSet.put(seenCards, cardKey)}
        true -> raise "Duplicate card found: #{cardKey}"
      end
    end)
  end
end
