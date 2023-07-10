defmodule Blackjack.Clients.Bot do
  @moduledoc """
  Provides a bot player for blackjack which will automatically pass/hit depending on their
  hand.
  """
  use GenServer

  alias Blackjack.Hand
  alias Blackjack.Round
  alias Blackjack.RoundServer

  @spec start(pid()) :: pid()
  def start(round_server) do
    {:ok, pid} = GenServer.start(__MODULE__, round_server)
    pid
  end

  @impl GenServer
  def init(round_server) do
    player_id = RoundServer.register_client(round_server)
    {:ok, {round_server, player_id}}
  end

  @impl GenServer
  def handle_cast({:blackjack_events, round, events}, {round_server, player_id}) do
    player = Round.get_player_by_id(round, player_id)

    if is_active_player?(round, player_id) do
      IO.puts("---")
      score = Hand.max_safe_score(player.hand)
      IO.puts("<#{player_id}> - It's my turn")

      IO.puts(
        "<#{player_id}> - My Hand: #{Hand.to_string(player.hand)} Dealer Hand: %#{Hand.to_string(round.dealer_hand)}"
      )

      IO.puts("<#{player_id}> - Thinking...")
      Process.sleep(3000)

      if score <= 16 do
        IO.puts("<#{player_id}> - Hit me!")
        Process.sleep(500)
        RoundServer.action_hit(round_server, player_id)
      else
        IO.puts("<#{player_id}> - Pass")
        Process.sleep(500)
        RoundServer.action_pass(round_server, player_id)
      end

      IO.puts("---")
    end

    round_complete_event = Enum.find(events, &(&1.type === :round_complete))

    if round_complete_event do
      player_result =
        Enum.find(round_complete_event.round_results, fn r -> r.player_id === player_id end)

      IO.puts(
        "<#{player_id}> - Round Result: #{player_result.result} My Score: #{player_result.score} Dealer Score: #{Hand.max_safe_score(round_complete_event.dealer_hand)} My Hand: #{Hand.to_string(player.hand)} Dealer Hand: %#{Hand.to_string(round.dealer_hand)}"
      )
    end

    {:noreply, {round_server, player_id}}
  end

  defp is_active_player?(round, player_id) do
    Round.get_active_player_id(round) === player_id
  end
end
