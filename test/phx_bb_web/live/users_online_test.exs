defmodule PhxBbWeb.UsersOnlineTest do
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

  test "Online users list updates live", %{conn: conn, user: user} do
    logged_in_conn = log_in_user(conn, user)
    {:ok, view, _html} = live(logged_in_conn, "/forum")

    assert has_element?(view, "#online-user-#{user.id}", user.username)
    refute render(view) =~ "guest"

    {:ok, view_2, _html} = live(conn, "/forum")

    assert render(view) =~ "guest"
    assert has_element?(view_2, "#online-user-#{user.id}", user.username)
  end
end
