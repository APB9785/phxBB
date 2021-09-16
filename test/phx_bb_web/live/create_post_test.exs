defmodule PhxBbWeb.CreatePostTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.ForumFixtures

  alias PhxBbWeb.UserAuth

  setup :register_and_log_in_user

  setup %{user: user} do
    board = board_fixture()

    %{
      board: board,
      topic: topic_fixture(user, board)
    }
  end

  test "Create a new post", %{conn: conn, topic: topic} do
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")
    {:ok, view_2, _html} = live(conn, "/forum?topic=#{topic.id}")

    assert has_element?(view, "#new-post-form")

    attrs = %{post: %{body: "I love Phoenix!"}}
    view |> form("#new-post-form", attrs) |> render_submit

    # Give time for the PubSub messages to be received
    _ = :sys.get_state(view.pid)

    assert render(view) =~ "I love Phoenix!"

    # Test live updates for other users viewing the same topic
    assert render(view_2) =~ "I love Phoenix!"
  end

  test "Post form live validations", %{conn: conn, topic: topic} do
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    view |> element("#new-post-form") |> render_change(%{post: %{body: "X"}})

    # This feature was removed in 0.5.1 and validation now waits for form submit
    refute has_element?(view, "#new-post-form", "should be at least 3 character(s)")
  end

  test "Attempt new post with invalid data", %{conn: conn, topic: topic} do
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    # Live validation was removed in 0.5.1
    view |> element("#new-post-form") |> render_change(%{post: %{body: "X"}})

    refute has_element?(view, "#new-post-form", "should be at least 3 character(s)")

    # Errors will still display after attempted form submission
    view |> form("#new-post-form", %{post: %{body: "OK"}}) |> render_submit

    assert has_element?(view, "#new-post-form", "should be at least 3 character(s)")
  end

  test "Logged-out users cannot see new post form", %{conn: conn, topic: topic} do
    conn = UserAuth.log_out_user(conn) |> recycle()
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    refute has_element?(view, "#new-post-form")
  end
end
