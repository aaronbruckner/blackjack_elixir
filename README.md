# Blackjack Elixir
My attempt to create a basic blackjack game as I learn Elixir.

# Todo Items
* Create player hand
  * Add card
  * Determine max value
  * Determine if bust
* Blackjack round
  * Determine current player
  * Allow hit from active player
  * Allow stand from active player
  * Resolve dealer hand
  * Determine winner
* Create client infrastructure
  * terminal client
  * Phoenix Client?
* Blackjack table
  * Allow people to join an active table and parcitipate in the next round?
  * Allow people to leave the table
  * Allow people to spectate the table?

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `blackjack_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:blackjack_elixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/blackjack_elixir>.

