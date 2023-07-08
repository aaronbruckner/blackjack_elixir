# Blackjack Elixir
My attempt to create a basic blackjack game as I learn Elixir.

## Run Basic Game Locally
```
iex -S mix

> {round, events} = Blackjack.Round.start_new_round(["p1", "p2"])

> {round, events} = Blackjack.Round.action_pass(round, "p1")

> {round, events} = Blackjack.Round.action_hit(round, "p2")
> {round, events} = Blackjack.Round.action_pass(round, "p2")
```
Players must take action in the correct order or their actions will be rejected. Once all players have passed or bust, dealer will resolve their actions and winners/losers are determined. Each action returns the modified round and a series of events which shows what happened within the game.