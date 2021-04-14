defmodule PhxBbWeb.PageLiveTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures
  import PhxBbWeb.LiveHelpers

  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Boards.Board
  alias PhxBb.Repo

  @test_board %Board{
    name: "Ontopic Discussion",
    description: "Test Board #1",
    post_count: 0,
    topic_count: 0,
    last_post: nil,
    last_user: nil
  }

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Welcome to the Forum!"
    assert render(page_live) =~ "Welcome to the Forum!"
  end

  test "navigation and viewing posts", %{conn: conn} do
    user = user_fixture()
    user_join_date = format_date(user.inserted_at)
    {:ok, board} = Repo.insert(@test_board)

    {:ok, view, _html} = live(conn, "/")

    # Main view before any posts are made
    assert has_element?(view, "#board-name", @test_board.name)
    assert has_element?(view, "#board-description", @test_board.description)
    assert has_element?(view, "#board-topic-count", "0 topics")
    assert has_element?(view, "#board-post-count", "0 posts")
    assert has_element?(view, "#no-posts-yet")

    {:ok, post} = postmaker("Test body", "Test title", board.id, user.id)
    # Update the last post info for the active board
    {1, _} = Boards.added_post(board.id, post.id, user.id)
    # Update the user's post count
    {1, _} = Accounts.added_post(user.id)

    {:ok, view, _html} = live(conn, "/")

    # Main view after 1 post is made
    assert has_element?(view, "#board-name", @test_board.name)
    assert has_element?(view, "#board-description", @test_board.description)
    assert has_element?(view, "#board-topic-count", "1 topic")
    assert has_element?(view, "#board-post-count", "1 post")
    assert has_element?(view, "#last-post-by", user.username)
    assert has_element?(view, "#last-post-link", "Test title")

    # Navigate to Board
    view
    |> element("#board-name", @test_board.name)
    |> render_click

    assert has_element?(view, "#breadcrumb", "Board Index")
    assert has_element?(view, "#board-header", @test_board.name)
    assert has_element?(view, "#post-listing", "Test title")

    # Navigate to Post
    view
    |> element("#post-listing-link", "Test title")
    |> render_click

    assert has_element?(view, "#post-header", "Test title")
    assert has_element?(view, "#post-author-info", user.username)
    assert has_element?(view, "#post-author-info", user.title)
    assert has_element?(view, "#author-post-count", "1")
    assert has_element?(view, "#author-join-date", user_join_date)

    # Invalid params
    {:ok, view, _html} = live(conn, "/?invalidparam=42")
    assert has_element?(view, "#page-not-found-live")
    {:ok, view, _html} = live(conn, "/?board=9999")
    assert has_element?(view, "#page-not-found-live")
    {:ok, view, _html} = live(conn, "/?post=9999")
    assert has_element?(view, "#page-not-found-live")

    # Return to Main Index from 404
    view
    |> element("#return-from-invalid")
    |> render_click

    assert has_element?(view, "#main-header")

    # Open Register dialog
    view
    |> element("#user-menu-register")
    |> render_click

    assert has_element?(view, "#register-header")
  end
end
