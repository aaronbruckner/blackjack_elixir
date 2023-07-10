# Blackjack Elixir
My attempt to create a basic blackjack game as I learn Elixir.

## Run Basic Game Locally
You can create a local game entirely under your control via:
```
iex -S mix

> {round, events} = Blackjack.Round.start_new_round(["p1", "p2"])

> {round, events} = Blackjack.Round.action_pass(round, "p1")

> {round, events} = Blackjack.Round.action_hit(round, "p2")
> {round, events} = Blackjack.Round.action_pass(round, "p2")
```
Players must take action in the correct order or their actions will be rejected. Once all players have passed or bust, dealer will resolve their actions and winners/losers are determined. Each action returns the modified round and a series of events which shows what happened within the game.


## Run Bot Game
`RoundServer` provides an experience closer to a real game by simulating players. You can spin up a game with bot players via:

```
iex -S mix

> round_server = Blackjack.RoundServer.start_with_bots(3)
> Blackjack.RoundServer.begin_round(round_server)
```
The bot servers will interact with `RoundServer` to hit or pass on the cards given to them.