defmodule PhxBbWeb.MessageTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures

  alias PhxBb.Messages

  setup do
    %{
      author: user_fixture(),
      recipient: user_fixture()
    }
  end

  test "Send, recieve, toggle read", %{conn: conn, author: author, recipient: recipient} do
    author_conn = log_in_user(conn, author)
    recipient_conn = log_in_user(conn, recipient)

    # There is no notification by default
    {:ok, recipient_view, _html} = live(recipient_conn, "/forum")
    refute has_element?(recipient_view, "#unread-message-notification")

    # Author will send a message to the recipient
    {:ok, author_view, _html} = live(author_conn, "/forum")

    author_view |> element("#user-menu-messages") |> render_click()
    author_view |> element("#new-message-link") |> render_click()

    attrs = %{
      recipient_id: recipient.id,
      body: "test body",
      subject: "test subject"
    }

    author_view |> form("#new-message-form", message: attrs) |> render_submit()

    assert has_element?(author_view, "#message-sent-ok")

    # Get message so we can use its ID later
    message = Messages.last_message_sent(author.id)

    # Ensure PubSub messages are received before moving forward
    _ = :sys.get_state(recipient_view.pid)

    # Recipient should have a new message
    assert has_element?(recipient_view, "#unread-message-notification")

    recipient_view |> element("#user-menu-messages") |> render_click()

    # Unread messages have a button to mark as read, which we will click
    recipient_view |> element("#mark-read-button-#{message.id}") |> render_click()

    # The button will switch to allow an undo, and the notification will clear
    assert has_element?(recipient_view, "#mark-unread-button-#{message.id}")
    refute has_element?(recipient_view, "#mark-read-button-#{message.id}")
    refute has_element?(recipient_view, "#unread-message-notification")

    # Clicking again will switch the button back, and the notification will re-appear
    recipient_view |> element("#mark-unread-button-#{message.id}") |> render_click()

    refute has_element?(recipient_view, "#mark-unread-button-#{message.id}")
    assert has_element?(recipient_view, "#mark-read-button-#{message.id}")
    assert has_element?(recipient_view, "#unread-message-notification")
  end
end
