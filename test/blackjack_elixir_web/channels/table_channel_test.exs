defmodule BlackjackElixirWeb.TableChannelTest do
  use BlackjackElixirWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      BlackjackElixirWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(BlackjackElixirWeb.TableChannel, "table:42")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to table:42", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
