defmodule PhxBbWeb.AdminPanelTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures
  import PhxBb.ForumFixtures

  setup %{conn: conn} do
    admin = user_fixture(%{admin: true})
    user = user_fixture()
    board = board_fixture()

    %{
      user: user,
      user_2: user_fixture(),
      board: board,
      topic: topic_fixture(user, board),
      admin: admin,
      user_conn: log_in_user(conn, user),
      admin_conn: log_in_user(conn, admin)
    }
  end

  test "Disable and re-enable a user account", context do
    {:ok, user_view, _html} = live(context[:user_conn], "/forum?board=#{context[:board].id}")
    assert has_element?(user_view, "#new-topic-button")

    {:ok, admin_view, _html} = live(context[:admin_conn], "/forum?admin=1")
    assert render(admin_view) =~ "Admin Panel"

    # Test validation first, then submit
    disable = %{disable_user: %{user: context[:user].id}}
    admin_view |> form("#admin-disable-user-form") |> render_change(disable)

    admin_view |> form("#admin-disable-user-form", disable) |> render_submit

    assert has_element?(admin_view, "#user-disabled-ok")
    admin_view |> element("#user-disabled-ok") |> render_click
    refute has_element?(admin_view, "#user-disabled-ok")

    # Disabling a second user ensures that the "#user-enabled-ok" alert
    # will be visible after re-enabling the first one
    disable_2 = %{disable_user: %{user: context[:user_2].id}}
    admin_view |> form("#admin-disable-user-form", disable_2) |> render_submit

    # Give time for the PubSub messages to be received
    _ = :sys.get_state(user_view.pid)
    refute has_element?(user_view, "#new-topic-button")

    # Even if they go to URL manually, the disabled user cannot post
    {:ok, user_view, _html} =
      live(context[:user_conn], "/forum?board=#{context[:board].id}&create_topic=1")

    attrs = %{new_topic: %{title: "a1s2d3", body: "j7k8l9"}}
    user_view |> form("#new-topic-form", attrs) |> render_submit

    user_view |> element("#crumb-board-link") |> render_click
    refute render(user_view) =~ "a1s2d3"

    # Disabled user cannot post
    user_view |> element("#topic-listing-link-#{context[:topic].id}") |> render_click
    user_view |> form("#new-post-form", %{post: %{body: "a1s2d3"}}) |> render_submit
    refute render(user_view) =~ "a1s2d3"

    user_view |> element("#crumb-board-link") |> render_click

    # Repeat for enabling
    enable = %{enable_user: %{user: context[:user].id}}
    admin_view |> form("#admin-enable-user-form") |> render_change(enable)

    admin_view |> form("#admin-enable-user-form") |> render_submit

    assert has_element?(admin_view, "#user-enabled-ok")
    admin_view |> element("#user-enabled-ok") |> render_click
    refute has_element?(admin_view, "#user-enabled-ok")

    _ = :sys.get_state(user_view.pid)
    assert has_element?(user_view, "#new-topic-button")
  end
end
