defmodule PhxBbWeb.UserConfirmationTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures

  alias PhxBb.Accounts
  alias PhxBb.Accounts.UserToken

  setup do
    %{user: user_fixture()}
  end

  test "Confirm a user account", %{conn: conn, user: user} do
    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    PhxBb.Repo.insert!(user_token)

    {:ok, new_conn} = live(conn, "/forum?confirm=#{encoded_token}") |> follow_redirect(conn)

    assert html_response(new_conn, 200) =~ "Account confirmed successfully."

    # Log in and try the same confirmation link again
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, "/forum?confirm=#{encoded_token}") |> follow_redirect(conn)

    assert has_element?(view, "#main-header")
  end

  test "Confirm an email change", %{conn: conn, user: user} do
    {:ok, applied_user} =
      Accounts.apply_user_email(user, "hello world!", %{email: "newemail@example.com"})

    {encoded_token, user_token} =
      UserToken.build_email_token(applied_user, "change:#{user.email}")

    PhxBb.Repo.insert!(user_token)

    conn = log_in_user(conn, user)

    {:ok, view, _html} =
      live(conn, "/forum?confirm_email=#{encoded_token}") |> follow_redirect(conn)

    assert render(view) =~ "Email changed successfully."
  end
end
