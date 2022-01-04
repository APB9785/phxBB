defmodule PhxBbWeb.PostTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.ForumFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    board = board_fixture()
    topic = topic_fixture(user, board) |> PhxBb.Repo.preload([:posts])
    [post] = topic.posts

    %{board: board, topic: topic, post: post}
  end

  test "Author info box", %{conn: conn, user: user, topic: topic, post: post} do
    user_join_date_fragment = "#{user.inserted_at.day}, #{user.inserted_at.year}"

    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    assert has_element?(view, "#post-#{post.id}-author-profile-link", user.username)
    assert has_element?(view, "#post-#{post.id}-author-title", user.title)
    assert has_element?(view, "#post-#{post.id}-author-post-count", "1")
    assert has_element?(view, "#post-#{post.id}-author-join-date", user_join_date_fragment)
  end

  test "Edit a post", %{conn: conn, user: user, topic: topic, post: post} do
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")
    {:ok, view_2, _html} = live(conn, "/forum?topic=#{topic.id}")

    view |> element("#edit-post-#{post.id}-link") |> render_click

    attrs = %{post: %{body: "Edited text"}}
    view |> form("#edit-post-#{post.id}-form", attrs) |> render_submit

    # Give time for the PubSub messages to be received
    _ = :sys.get_state(view.pid)

    assert has_element?(view, "#post-#{post.id}-body", "Edited text")
    assert has_element?(view, "#post-#{post.id}-body", "Edited by #{user.username}")
    refute has_element?(view, "#edit-post-#{post.id}-form")

    # Test live updates for other users viewing the same topic
    assert has_element?(view_2, "#post-#{post.id}-body", "Edited text")
    assert has_element?(view_2, "#post-#{post.id}-body", "Edited by #{user.username}")
  end

  test "Validate post edits", %{conn: conn, topic: topic, post: post} do
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    # Live validations
    view |> element("#edit-post-#{post.id}-link") |> render_click
    view |> element("#edit-post-#{post.id}-form") |> render_change(%{post: %{body: "X"}})

    assert has_element?(view, "#edit-post-#{post.id}-form", "should be at least 3 character(s)")

    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    # Attempt form submission with invalid data
    view |> element("#edit-post-#{post.id}-link") |> render_click
    view |> form("#edit-post-#{post.id}-form", %{post: %{body: "X"}}) |> render_submit

    assert has_element?(view, "#edit-post-#{post.id}-form", "should be at least 3 character(s)")
  end

  test "Cancel a post edit", %{conn: conn, user: user, topic: topic, post: post} do
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    view |> element("#edit-post-#{post.id}-link") |> render_click

    assert has_element?(view, "#edit-post-#{post.id}-form")

    view |> element("#cancel-post-#{post.id}-edit") |> render_click

    refute has_element?(view, "#edit-post-#{post.id}-form")
    assert has_element?(view, "#post-#{post.id}-body", "test body")
    refute has_element?(view, "#post-#{post.id}-body", "Edited by #{user.username}")
  end

  test "Delete a post", %{conn: conn, user: user, topic: topic, post: post} do
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")
    {:ok, view_2, _html} = live(conn, "/forum?topic=#{topic.id}")

    assert has_element?(view, "#post-#{post.id}-body", "test body")

    view |> element("#delete-post-#{post.id}") |> render_click

    # Give time for the PubSub messages to be received
    _ = :sys.get_state(view.pid)

    refute has_element?(view, "#post-#{post.id}-body", "test body")
    assert has_element?(view, "#post-#{post.id}-body", "Post deleted")
    assert has_element?(view, "#post-#{post.id}-body", "Edited by #{user.username}")

    # Test live updates for other users viewing the same topic
    refute has_element?(view_2, "#post-#{post.id}-body", "test body")
    assert has_element?(view_2, "#post-#{post.id}-body", "Post deleted")
    assert has_element?(view_2, "#post-#{post.id}-body", "Edited by #{user.username}")
  end
end
