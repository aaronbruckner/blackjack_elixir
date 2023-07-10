defmodule Blackjack.RoundServer do
  @moduledoc """
  Hosts a "table" of blackjack. Allows clients to register and play a game of blackjack.
  """
  alias Blackjack.Player
  alias Blackjack.Event
  alias Blackjack.Round
  alias Blackjack.RoundServer
  alias Blackjack.Clients.Bot
  use GenServer

  @type t :: %__MODULE__{
          player_id_to_pid_map: %{required(Player.player_id()) => pid()},
          round: Round.t(),
          next_player_id: integer()
        }

  defstruct [:player_id_to_pid_map, :round, :next_player_id]

  def start() do
    {:ok, round_server} = GenServer.start(__MODULE__, nil)
    round_server
  end

  @spec start_with_bots(integer()) :: pid()
  def start_with_bots(total_bots) do
    round_server = start()

    Enum.each(1..total_bots, fn id ->
      IO.puts("Starting Bot #{id}")
      Bot.start(round_server)
    end)

    round_server
  end

  @spec register_client(pid()) :: Player.player_id()
  def register_client(server) do
    GenServer.call(server, {:register_client}, :infinity)
  end

  @spec begin_round(pid()) :: any()
  def begin_round(server) do
    GenServer.cast(server, {:begin_round})
  end

  @spec action_pass(pid(), Player.player_id()) :: any()
  def action_pass(server, player_id) do
    GenServer.cast(server, {:action_pass, player_id})
  end

  @spec action_hit(pid(), Player.player_id()) :: any()
  def action_hit(server, player_id) do
    GenServer.cast(server, {:action_hit, player_id})
  end

  @impl GenServer
  def init(_options) do
    {:ok, %RoundServer{player_id_to_pid_map: %{}, next_player_id: 0, round: nil}}
  end

  @impl GenServer
  def handle_call({:register_client}, {pid, _tag}, state) do
    {nextState, player_id} = add_new_player(state, pid)
    {:reply, player_id, nextState}
  end

  @impl GenServer
  def handle_cast({:begin_round}, state) do
    {round, events} = Round.start_new_round(Map.keys(state.player_id_to_pid_map))
    nextState = %RoundServer{state | round: round}
    broadcast_events(nextState, events)
    {:noreply, nextState}
  end

  @impl GenServer
  def handle_cast({:action_pass, player_id}, state) do
    {round, events} = Round.action_pass(state.round, player_id)
    nextState = %RoundServer{state | round: round}
    broadcast_events(nextState, events)
    {:noreply, nextState}
  end

  @impl GenServer
  def handle_cast({:action_hit, player_id}, state) do
    {round, events} = Round.action_hit(state.round, player_id)
    nextState = %RoundServer{state | round: round}
    broadcast_events(nextState, events)
    {:noreply, nextState}
  end

  @spec broadcast_events(t(), list(Event.t())) :: any()
  defp broadcast_events(state, events) do
    Enum.each(Map.values(state.player_id_to_pid_map), fn pid ->
      GenServer.cast(pid, {:blackjack_events, Round.make_client_safe(state.round), events})
    end)
  end

  @spec add_new_player(t(), pid()) :: {t(), Player.player_id()}
  defp add_new_player(state, pid) do
    player_id = "Player_#{state.next_player_id}"

    nextState = %RoundServer{
      state
      | player_id_to_pid_map: Map.put(state.player_id_to_pid_map, player_id, pid),
        next_player_id: state.next_player_id + 1
    }

    {nextState, player_id}
  end
end
