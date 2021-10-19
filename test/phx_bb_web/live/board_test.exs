defmodule PhxBbWeb.BoardTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures
  import PhxBb.ForumFixtures

  setup do
    %{
      user: user_fixture(),
      board: board_fixture()
    }
  end

  test "topic post count", %{conn: conn, user: user, board: board} do
    topic = topic_fixture(user, board)
    Enum.each(0..4, fn _ -> post_fixture(user, topic) end)

    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}")

    render(view) =~ "6 posts"
  end

  test "scroll list of topics", %{conn: conn, user: user, board: board} do
    Enum.each(0..4, fn x ->
      topic_fixture(user, board, "Test-#{x}")
    end)

    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}")

    assert render(view) =~ "Test-0"
    assert render(view) =~ "Test-4"

    # Sleep for a second to ensure the timestamp for the next batch of topics
    # is later than the previous batch
    Process.sleep(1000)

    Enum.each(5..9, fn x ->
      topic_fixture(user, board, "Test-#{x}")
    end)

    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}")

    # Only the latter batch is displayed
    assert render(view) =~ "Test-5"
    assert render(view) =~ "Test-9"
    refute render(view) =~ "Test-0"

    # Simulate the InfiniteScroll hook
    view |> find_live_child("board-liveview") |> render_hook("load_more")

    # Now all 10 topics should be visible
    assert render(view) =~ "Test-0"
    assert render(view) =~ "Test-1"
    assert render(view) =~ "Test-9"
  end
end
