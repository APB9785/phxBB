defmodule PhxBbWeb.CreateTopicTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.ForumFixtures

  setup :register_and_log_in_user

  setup do
    %{board: board_fixture()}
  end

  test "Create a new topic", %{conn: conn, board: board} do
    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}")

    view |> element("#new-topic-button") |> render_click

    attrs = %{new_topic: %{title: "Hello XYZ", body: "Elixir is awesome!"}}
    view |> form("#new-topic-form", attrs) |> render_submit

    assert has_element?(view, "#board-header", board.name)
    assert render(view) =~ "Hello XYZ"
  end

  test "New topic live validations", %{conn: conn, board: board} do
    {:ok, view, _html} = live(conn, "/forum?board=#{board.id}&create_topic=1")

    attrs = %{new_topic: %{title: "", body: "X"}}
    view |> element("#new-topic-form") |> render_change(attrs)

    assert has_element?(view, "#new-topic-form", "can't be blank")
    assert has_element?(view, "#new-topic-form", "should be at least 3 character(s)")
  end
end
