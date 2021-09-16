defmodule PhxBbWeb.UserRegistrationTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures
  import Swoosh.TestAssertions

  setup :set_swoosh_global

  setup do
    %{user: user_fixture()}
  end

  test "Register new user", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?register=1")

    assert has_element?(view, "#register-header")

    attrs = %{
      user: %{
        email: "test_user@example.com",
        username: "testie",
        password: "test1234",
        timezone: "Etc/UTC"
      }
    }

    view |> form("#register-new-user-form", attrs) |> render_submit

    flash = assert_redirected(view, "/users/log_in")
    assert flash["info"] =~ "User created successfully. Please check your email"
    assert_email_sent()
  end

  test "Render errors for invalid data", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/forum?register=1")

    attrs = %{
      user: %{
        email: "invalid_tester examplecom",
        username: "tester2000",
        password: "short",
        timezone: "Etc/UTC"
      }
    }

    view |> form("#register-new-user-form", attrs) |> render_submit

    assert has_element?(view, "#register-new-user-form", "should be at least 8 character(s)")
    assert has_element?(view, "#register-new-user-form", "must have the @ sign and no spaces")
  end

  test "Redirect if already logged in", %{conn: conn, user: user} do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, "/forum?register=1") |> follow_redirect(conn)

    assert has_element?(view, "#main-header")
    assert render(view) =~ "You are already registered and logged in."
  end
end
