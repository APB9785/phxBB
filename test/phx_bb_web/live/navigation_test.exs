defmodule PhxBbWeb.NavigationTest do
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

  test "Visit a board directly from URL", %{conn: conn, board: board} do
    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}")
    assert has_element?(view, "#board-header", board.name)
  end

  test "Return to Main Index from 404", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?invalid=9999")

    view |> element("#return-from-invalid") |> render_click

    assert has_element?(view, "#main-header")
  end

  test "Visit a user profile from Main Index", %{conn: conn, user: user, board: board} do
    _topic = topic_fixture(user, board)
    {:ok, view, _html} = live(conn, "/forum")

    view |> element("#board-#{board.id}-recent-author-link") |> render_click

    assert has_element?(view, "#user-profile-header")
  end

  test "Visit pages which require login", %{conn: conn, board: board} do
    live(conn, "/forum?settings=1")
    |> follow_redirect(conn, "/users/log_in")

    live(conn, "/forum?board=#{board.id}&create_topic=1")
    |> follow_redirect(conn, "/users/log_in")
  end

  test "Regular users cannot access Admin Panel", %{conn: conn, user: user} do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, "/forum?admin=1")

    assert has_element?(view, "#page-not-found-live")
  end

  test "Invalid URL params", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/forum?invalidparam=42")
    assert has_element?(view, "#page-not-found-live")

    {:ok, view, _html} = live(conn, "/forum?board=9999")
    assert has_element?(view, "#page-not-found-live")

    {:ok, view, _html} = live(conn, "/forum?topic=9999")
    assert has_element?(view, "#page-not-found-live")

    {:ok, view, _html} = live(conn, "/forum?user=9999")
    assert has_element?(view, "#page-not-found-live")

    # This is valid but hidden
    {:ok, view, _html} = live(conn, "/forum?admin=1")
    assert has_element?(view, "#page-not-found-live")

    # Invalid board has no create_topic page
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, "/forum?board=9999999&create_topic=1")
    assert has_element?(view, "#page-not-found-live")
  end

  test "Invalid confirmation tokens", %{conn: conn} do
    live(conn, "/forum?confirm=123456789")
    |> follow_redirect(conn, "/forum")

    live(conn, "/forum?confirm_email=123456789")
    |> follow_redirect(conn, "/forum")
  end

  test "Breadcrumb from topic to board", %{conn: conn, user: user, board: board} do
    topic = topic_fixture(user, board)
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    view |> element("#crumb-board-link") |> render_click

    assert has_element?(view, "#board-header")
  end

  test "Breadcrumb from topic to main index", %{conn: conn, user: user, board: board} do
    topic = topic_fixture(user, board)
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    view |> element("#crumb-index-link") |> render_click

    assert has_element?(view, "#main-header")
  end

  test "Breadcrumb from board to main index", %{conn: conn, board: board} do
    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}")

    view |> element("#crumb-index-link") |> render_click

    assert has_element?(view, "#main-header")
  end

  test "Breadcrumb from settings to main index", %{conn: conn, user: user} do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    view |> element("#crumb-index-link") |> render_click

    assert has_element?(view, "#main-header")
  end

  test "Breadcrumb from user profile to main index", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/forum?user=#{user.id}")

    view |> element("#crumb-index-link") |> render_click

    assert has_element?(view, "#main-header")
  end

  test "Breadcrumb from registration to main index", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?register=1")

    view |> element("#crumb-index-link") |> render_click

    assert has_element?(view, "#main-header")
  end

  test "Breadcrumb from new topic form to board", %{conn: conn, user: user, board: board} do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}&create_topic=1")

    view |> element("#crumb-board-link") |> render_click

    assert has_element?(view, "#board-header")
  end

  test "Breadcrumb from new topic form to main index", %{conn: conn, user: user, board: board} do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}&create_topic=1")

    view |> element("#crumb-index-link") |> render_click

    assert has_element?(view, "#main-header")
  end

  test "Breadcrumb from admin panel to main index", %{conn: conn} do
    admin_user = user_fixture(%{admin: true})
    conn = log_in_user(conn, admin_user)
    {:ok, view, _html} = live(conn, "/forum?admin=1")

    view |> element("#crumb-index-link") |> render_click

    assert has_element?(view, "#main-header")
  end
end
