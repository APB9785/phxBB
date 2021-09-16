defmodule PhxBbWeb.UserSettingsTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.ForumFixtures
  import Swoosh.TestAssertions

  setup :set_swoosh_global
  setup :register_and_log_in_user

  setup do
    %{board: board_fixture()}
  end

  test "Re-send user confirmation link", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    view |> element("#resend-verification-button") |> render_click

    assert_email_sent()
    assert has_element?(view, "#confirmation-resent-ok")

    view |> element("#confirmation-resent-ok") |> render_click

    refute has_element?(view, "#confirmation-resent-ok")
  end

  test "Update user email address", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{user: %{email: "another_email@example.com"}, current_password: "hello world!"}
    view |> form("#update-user-email-form", attrs) |> render_submit

    assert_email_sent()
    assert has_element?(view, "#email-updated-ok")

    view |> element("#email-updated-ok") |> render_click

    refute has_element?(view, "#email-updated-ok")
  end

  test "Fail to update user email address", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{user: %{email: user.email}, current_password: "hello world!"}
    view |> form("#update-user-email-form", attrs) |> render_submit

    assert has_element?(view, "#update-user-email-form", "did not change")
  end

  test "Update user title", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum")

    view |> element("#user-menu-settings") |> render_click

    attrs = %{user: %{title: "Expert"}}
    view |> form("#change-user-title-form", attrs) |> render_submit

    assert has_element?(view, "#title-updated-ok")

    view |> element("#title-updated-ok") |> render_click

    refute has_element?(view, "#title-updated-ok")
  end

  test "Attempt invalid user title update", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{user: %{title: "abcdefghijklmnopqrstuvwxyz"}}
    view |> form("#change-user-title-form", attrs) |> render_submit

    assert has_element?(view, "#title-update-failed")
    assert has_element?(view, "#change-user-title-form", "should be at most")
  end

  test "Update user timezone", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{user: %{timezone: "US/Central"}}
    view |> form("#change-user-timezone-form", attrs) |> render_submit

    assert has_element?(view, "#timezone-updated-ok")

    view |> element("#timezone-updated-ok") |> render_click

    refute has_element?(view, "#timezone-updated-ok")
  end

  test "Attempt invalid timezone update", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{user: %{timezone: "Etc/UTC"}}
    view |> form("#change-user-timezone-form", attrs) |> render_submit

    assert has_element?(view, "#change-user-timezone-form", "did not change")
  end

  test "Upload, view, and remove user avatar", %{conn: conn, user: user, board: board} do
    topic = topic_fixture(user, board) |> PhxBb.Repo.preload([:posts])
    [post] = topic.posts

    {:ok, view, _html} = live(conn, "/forum?settings=1")

    refute render(view) =~ "100%"
    refute has_element?(view, "#remove-avatar-link")

    avatar =
      file_input(view, "#change-user-avatar-form", :avatar, [
        %{
          last_modified: 1_594_171_879_000,
          name: "elixir.png",
          content: File.read!("test/support/fixtures/elixir.png"),
          size: 2_118,
          type: "image/png"
        }
      ])

    assert render_upload(avatar, "elixir.png") =~ "100%"

    view |> element("#change-user-avatar-form") |> render_submit

    assert has_element?(view, "#avatar-updated-ok")

    view |> element("#avatar-updated-ok") |> render_click

    refute has_element?(view, "#avatar-updated-ok")

    # Avatar should be uploaded OK, now see if it displays
    {:ok, view, _html} = live(conn, "/forum?topic=#{topic.id}")

    assert has_element?(view, "#post-#{post.id}-author-avatar")

    # Remove the avatar
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    view |> element("#remove-avatar-link") |> render_click

    assert has_element?(view, "#avatar-removed-ok")

    view |> element("#avatar-removed-ok") |> render_click

    refute has_element?(view, "#avatar-removed-ok")
  end

  test "Discard avatar before uploading", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    avatar =
      file_input(view, "#change-user-avatar-form", :avatar, [
        %{
          last_modified: 1_594_171_879_000,
          name: "elixir.png",
          content: File.read!("test/support/fixtures/elixir.png"),
          size: 2_118,
          type: "image/png"
        }
      ])

    render_upload(avatar, "elixir.png")

    assert has_element?(view, "#avatar-preview")

    view |> element("#cancel-upload") |> render_click

    refute has_element?(view, "#avatar-preview")
  end

  test "Attempt to upload oversized avatar", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    avatar =
      file_input(view, "#change-user-avatar-form", :avatar, [
        %{
          last_modified: 1_594_171_879_000,
          name: "too_large.jpg",
          content: File.read!("test/support/fixtures/elixir.png"),
          size: 158_894,
          type: "image/png"
        }
      ])

    assert view
           |> element("#change-user-avatar-form")
           |> render_change(avatar) =~ "Too large"
  end

  test "Attempt to change avatar with no file selected", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    view |> form("#change-user-avatar-form", %{}) |> render_submit

    assert has_element?(view, "#avatar-submit-error", "no file was selected")
  end

  test "Change theme", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{user: %{theme: "elixir"}}
    view |> form("#change-user-theme-form", attrs) |> render_submit

    assert has_element?(view, "#theme-changed-ok")

    view |> element("#theme-changed-ok") |> render_click

    refute has_element?(view, "#theme-changed-ok")
    assert render(view) =~ "bg-purple-700"
  end

  test "Fail to change theme", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{user: %{theme: "dark"}}
    view |> form("#change-user-theme-form", attrs) |> render_submit

    assert has_element?(view, "#theme-change-failed")
  end

  test "Change user password", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{
      user: %{
        password: "another pass",
        password_confirmation: "another pass"
      },
      current_password: "hello world!"
    }

    view |> form("#change-user-password-form", attrs) |> render_submit

    flash = assert_redirected(view, "/users/log_in")
    assert flash["info"] == "Password updated successfully.  Please log in again."
  end

  test "Failure to change user password", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?settings=1")

    attrs = %{
      user: %{
        password: "short",
        password_confirmation: "short"
      },
      current_password: "hello world!"
    }

    view |> form("#change-user-password-form", attrs) |> render_submit

    assert has_element?(view, "#change-user-password-form", "should be at least 8 character(s)")
  end
end
