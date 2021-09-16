defmodule PhxBbWeb.MainIndexTest do
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

  test "Long topic title shortened", %{conn: conn, user: user, board: board} do
    long_title = String.duplicate("AbcXyz", 20)
    shortened_title = "AbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcX..."
    _topic = topic_fixture(user, board, long_title)
    {:ok, view, _html} = live(conn, "/forum")

    assert has_element?(view, "#board-#{board.id}-recent-topic-link", shortened_title)
  end

  test "Main view before any posts are made", %{conn: conn, board: board} do
    {:ok, view, _html} = live(conn, "/forum")

    assert has_element?(view, "#board-#{board.id}-link", board.name)
    assert has_element?(view, "#board-#{board.id}-description", board.description)
    assert has_element?(view, "#board-#{board.id}-topic-count", "0 topics")
    assert has_element?(view, "#board-#{board.id}-post-count", "0 posts")
    assert has_element?(view, "#board-#{board.id}-no-topics-yet")
  end

  test "Main view after one topic is made", %{conn: conn, user: user, board: board} do
    topic = topic_fixture(user, board)
    {:ok, view, _html} = live(conn, "/forum")

    assert has_element?(view, "#board-#{board.id}-link", board.name)
    assert has_element?(view, "#board-#{board.id}-description", board.description)
    assert has_element?(view, "#board-#{board.id}-topic-count", "1 topic")
    assert has_element?(view, "#board-#{board.id}-post-count", "1 post")
    assert has_element?(view, "#board-#{board.id}-recent-author-link", user.username)
    assert has_element?(view, "#board-#{board.id}-recent-topic-link", topic.title)
  end
end
