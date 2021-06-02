defmodule PhxBbWeb.PageLiveTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures
  import PhxBbWeb.LiveHelpers

  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Boards.Board
  alias PhxBb.Posts
  alias PhxBb.Repo
  alias PhxBbWeb.UserAuth

  @test_board %Board{
    name: "Ontopic Discussion",
    description: "Test Board #1",
    post_count: 0,
    topic_count: 0,
    last_post: nil,
    last_user: nil
  }

  @board_2 %Board{
    name: "Sample Topic",
    description: "Test Board #2",
    post_count: 0,
    topic_count: 0,
    last_post: nil,
    last_user: nil
  }

  setup do
    %{
      user: user_fixture(),
      board: Repo.insert!(@test_board)
    }
  end

  describe "Logged-out User:" do
    test "Main view before any posts are made", %{conn: conn, board: board} do
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#board-name", board.name)
      assert has_element?(view, "#board-description", board.description)
      assert has_element?(view, "#board-topic-count", "0 topics")
      assert has_element?(view, "#board-post-count", "0 posts")
      assert has_element?(view, "#no-posts-yet")
      assert has_element?(view, "#logged-out-menu")
    end

    test "Main view after one post is made", %{conn: conn, user: user, board: board} do
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#board-name", board.name)
      assert has_element?(view, "#board-description", board.description)
      assert has_element?(view, "#board-topic-count", "1 topic")
      assert has_element?(view, "#board-post-count", "1 post")
      assert has_element?(view, "#last-post-by", user.username)
      assert has_element?(view, "#last-post-link", post.title)
    end

    test "Revisit the active post", %{conn: conn, user: user, board: board} do
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      view |> element("#crumb-board") |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
    end

    test "Irrelevant PubSub message", %{conn: conn, user: user, board: board} do
      alt_user = user_fixture()
      post = post_fixture(user, board, "First Title")
      alt_post = post_fixture(user, board, "Second Title")
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click

      {:ok, reply} = replymaker("Test reply", alt_post.id, alt_user)
      message = {:new_reply, alt_post.id, reply, alt_user.id}
      Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

      # This should run OK but have no visible effect
    end

    test "Visit a board directly from URL", %{conn: conn, board: board} do
      {:ok, view, _html} = live(conn, "/?board=#{board.id}")
      assert has_element?(view, "#board-header", board.name)
    end

    test "Long topic title shortened in Main view", %{conn: conn, user: user, board: board} do
      long_title = String.duplicate("AbcXyz", 20)
      shortened_title = "AbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcX..."
      _post = post_fixture(user, board, long_title)
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#last-post-link", shortened_title)
    end

    test "Post author info box", %{conn: conn, user: user, board: board} do
      post = post_fixture(user, board)
      user_join_date_fragment = "#{user.inserted_at.day}, #{user.inserted_at.year}"
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click

      assert has_element?(view, "#post-author-info", user.username)
      assert has_element?(view, "#post-author-info", user.title)
      assert has_element?(view, "#author-post-count", "1")
      assert has_element?(view, "#author-join-date", user_join_date_fragment)
    end

    test "Cannot see new reply form", %{conn: conn, user: user, board: board} do
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click

      refute has_element?(view, "#new-reply-form")
    end

    test "Invalid confirmation tokens", %{conn: conn} do
      live(conn, "/?confirm=123456789")
      |> follow_redirect(conn, "/")

      live(conn, "/?confirm_email=123456789")
      |> follow_redirect(conn, "/")
    end

    test "Visit pages which require login", %{conn: conn} do
      live(conn, "/?settings=1")
      |> follow_redirect(conn, "/users/log_in")

      live(conn, "/?board=1&create_post=1")
      |> follow_redirect(conn, "/users/log_in")
    end

    test "Invalid URL params", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?invalidparam=42")
      assert has_element?(view, "#page-not-found-live")

      {:ok, view, _html} = live(conn, "/?board=9999")
      assert has_element?(view, "#page-not-found-live")

      {:ok, view, _html} = live(conn, "/?post=9999")
      assert has_element?(view, "#page-not-found-live")

      {:ok, view, _html} = live(conn, "/?user=9999")
      assert has_element?(view, "#page-not-found-live")

      # This is valid but hidden
      {:ok, view, _html} = live(conn, "/?admin=1")
      assert has_element?(view, "#page-not-found-live")
    end

    test "Register new user", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("#user-menu-register") |> render_click

      assert has_element?(view, "#register-header")

      view
      |> form("#register-new-user-form", %{
        user: %{
          email: "test_user@example.com",
          username: "testie",
          password: "test1234",
          timezone: "Etc/UTC"
        }
      })
      |> render_submit

      flash = assert_redirected(view, "/users/log_in")
      assert flash["info"] =~ "User created successfully. Please check your email"
    end

    test "Fail to register new user", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?register=1")

      view
      |> form("#register-new-user-form", %{
        user: %{
          email: "invalid_tester@example.com",
          username: "tester2000",
          password: "short",
          timezone: "Etc/UTC"
        }
      })
      |> render_submit

      assert has_element?(view, "#register-new-user-form", "should be at least 8 character(s)")
    end

    test "Return to Main Index from 404", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?invalid=9999")

      view |> element("#return-from-invalid") |> render_click

      assert has_element?(view, "#main-header")
    end

    test "Visit a user profile from Main Index", %{conn: conn, user: user, board: board} do
      _post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")

      view |> element("#last-post-author-link") |> render_click

      assert has_element?(view, "#user-profile-header")
    end

    test "Confirm a user account", %{conn: conn, user: user} do
      token = Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)
      {:ok, conn} = live(conn, "/?confirm=#{token}") |> follow_redirect(conn)

      assert html_response(conn, 200) =~ "Account confirmed successfully."
    end

    test "Board updated when navigating between posts", %{conn: conn, user: user, board: board} do
      new_board = Repo.insert!(@board_2)
      post = post_fixture(user, new_board)
      {:ok, view, _html} = live(conn, "/")

      # Active board is set by navigating to board 1
      view |> element("#board-name", board.name) |> render_click
      assert has_element?(view, "#board-header", board.name)

      # Return to Main Index
      view |> element("#crumb-index") |> render_click
      assert has_element?(view, "#main-header")

      # Visiting a post in another board changes the active board
      view |> element("#last-post-link", post.title) |> render_click
      assert has_element?(view, "#post-header", post.title)
      assert has_element?(view, "#crumb-board", new_board.name)
    end

    test "Title change by an unknown user", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:user_title_change, 9999, "irrelevant"})

      # Nothing happens, LV still alive
      assert has_element?(view, "#main-header")
    end

    test "New unseen post by an unknown user", %{conn: conn, user: user, board: board} do
      post = post_fixture(user, board)
      user_2 = user_fixture()
      {:ok, view, _html} = live(conn, "/")
      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      _post_2 = post_fixture(user_2, board)

      # Nothing happens, LV still alive
      assert has_element?(view, "#post-header", post.title)
    end
  end

  describe "Logged-in User:" do
    test "Create a new topic and reply", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#logged-in-menu", user.username)

      view |> element("#board-name", board.name) |> render_click
      view |> element("#new-post-button-top") |> render_click

      assert has_element?(view, "#create-topic-header")

      view
      |> form("#new-topic-form", %{post: %{title: "Hello World", body: "Elixir is awesome!"}})
      |> render_submit

      assert has_element?(view, "#board-header", board.name)
      assert has_element?(view, "#post-listing", "Hello World")

      view |> element("#post-listing-link", "Hello World") |> render_click

      assert has_element?(view, "#breadcrumb", board.name)
      assert has_element?(view, "#post-header", "Hello World")
      assert has_element?(view, "#new-reply-form")

      # Create a new reply
      view
      |> form("#new-reply-form", %{reply: %{body: "I love Phoenix"}})
      |> render_submit

      assert render(view) =~ "I love Phoenix"
    end

    test "Re-send user confirmation link", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view |> element("#resend-verification-button") |> render_click

      assert has_element?(view, "#confirmation-resent-ok")
      view |> element("#confirmation-resent-ok") |> render_click
      refute has_element?(view, "#confirmation-resent-ok")
    end

    test "Update user email address", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#update-user-email-form", %{
        user: %{email: "another_email@example.com"},
        current_password: "hello world!"
      })
      |> render_submit

      assert has_element?(view, "#email-updated-ok")
      view |> element("#email-updated-ok") |> render_click
      refute has_element?(view, "#email-updated-ok")
    end

    test "Fail to update user email address", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#update-user-email-form", %{
        user: %{email: user.email},
        current_password: "hello world!"
      })
      |> render_submit

      assert has_element?(view, "#update-user-email-form", "did not change")
    end

    test "Update user title", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")

      view |> element("#user-menu-settings") |> render_click

      view
      |> form("#change-user-title-form", %{user: %{title: "Expert"}})
      |> render_submit

      assert has_element?(view, "#title-updated-ok")
      view |> element("#title-updated-ok") |> render_click
      refute has_element?(view, "#title-updated-ok")
    end

    test "Attempt invalid user title update", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-title-form", %{user: %{title: "abcdefghijklmnopqrstuvwxyz"}})
      |> render_submit

      assert has_element?(view, "#title-update-failed")
      assert has_element?(view, "#change-user-title-form", "should be at most")
    end

    test "Update user timezone", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-timezone-form", %{user: %{timezone: "US/Central"}})
      |> render_submit

      assert has_element?(view, "#timezone-updated-ok")
      view |> element("#timezone-updated-ok") |> render_click
      refute has_element?(view, "#timezone-updated-ok")
    end

    test "Attempt invalid timezone update", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-timezone-form", %{user: %{timezone: "Etc/UTC"}})
      |> render_submit

      assert has_element?(view, "#change-user-timezone-form", "did not change")
    end

    test "Upload, view, and remove user avatar", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/?settings=1")

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

      # Avatar should be uploaded OK, now see if it displays
      {:ok, view, _html} = live(conn, "/?post=#{post.id}")
      assert has_element?(view, "#post-author-avatar-#{post.id}")

      # Remove the avatar
      {:ok, view, _html} = live(conn, "/?settings=1")
      view |> element("#remove-avatar-link") |> render_click
      assert render(view) =~ "User avatar removed successfully."
    end

    test "Discard avatar before uploading", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

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

    test "Attempt to upload oversized avatar", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

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

    test "Change theme", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-theme-form", %{user: %{theme: "dark"}})
      |> render_submit

      assert has_element?(view, "#theme-changed-ok")
      view |> element("#theme-changed-ok") |> render_click
      refute has_element?(view, "#theme-changed-ok")

      {:ok, view, _html} = live(conn, "/?create=1&board=#{board.id}")
      assert render(view) =~ "bg-gray-900"
    end

    test "Fail to change theme", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-theme-form", %{user: %{theme: "default"}})
      |> render_submit

      assert has_element?(view, "#theme-change-failed")
    end

    test "Attempt to change avatar with no file selected", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view |> form("#change-user-avatar-form", %{}) |> render_submit

      assert has_element?(view, "#avatar-submit-error", "no file was selected")
    end

    test "Reply form live validations", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/?post=#{post.id}")

      view |> element("#new-reply-form") |> render_change(%{reply: %{body: "X"}})

      # This feature was removed in 0.5.1 and validation now waits for form submit
      refute has_element?(view, "#new-reply-form", "should be at least 3 character(s)")
    end

    test "Return to Main Index via breadcrumb", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view |> element("#crumb-index") |> render_click

      assert has_element?(view, "#main-header")
    end

    test "Register link leads to Main Index", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?register=1") |> follow_redirect(conn)

      assert has_element?(view, "#main-header")
      assert render(view) =~ "You are already registered and logged in."
    end

    test "Change user password", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-password-form", %{
        user: %{password: "another pass", password_confirmation: "another pass"},
        current_password: "hello world!"
      })
      |> render_submit

      flash = assert_redirected(view, "/users/log_in")
      assert flash["info"] == "Password updated successfully.  Please log in again."
    end

    test "Failure to change user password", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-password-form", %{
        user: %{password: "short", password_confirmation: "short"},
        current_password: "hello world!"
      })
      |> render_submit

      assert has_element?(view, "#change-user-password-form", "should be at least 8 character(s)")
    end

    test "Create new topic in nonexistent board", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?board=9999&create_post=1")

      assert has_element?(view, "#page-not-found-live")
    end

    test "New topic form via URL", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?board=#{board.id}&create_post=1")

      assert has_element?(view, "#new-topic-form")
    end

    test "Fail to create new topic", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?board=#{board.id}&create_post=1")

      view
      |> form("#new-topic-form", %{post: %{body: "Test body", title: "X"}})
      |> render_submit

      assert has_element?(view, "#new-topic-form", "should be at least 3 character(s)")
    end

    test "Fail to create new reply", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/?post=#{post.id}")

      view |> form("#new-reply-form", %{reply: %{body: "OK"}}) |> render_submit

      assert has_element?(view, "#new-reply-form", "should be at least 3 character(s)")
    end

    test "Confirm a user account", %{conn: conn, user: user} do
      token = Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)
      {:ok, new_conn} = live(conn, "/?confirm=#{token}") |> follow_redirect(conn)

      assert html_response(new_conn, 200) =~ "Account confirmed successfully."

      # Log in and try the same confirmation link again
      conn = login_fixture(conn, user)
      {:ok, final_conn} = live(conn, "/?confirm=#{token}") |> follow_redirect(conn)

      assert html_response(final_conn, 200) =~ "Welcome to the Forum!"
    end

    test "Confirm an email change", %{conn: conn, user: user} do
      {:ok, applied_user} =
        Accounts.apply_user_email(user, "hello world!", %{email: "newemail@example.com"})

      token =
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &add_confirm_email_param/1
        )

      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?confirm_email=#{token}") |> follow_redirect(conn)

      assert render(view) =~ "Email changed successfully."
    end

    test "Edit a post", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      view |> element("#edit-post-link-#{post.id}") |> render_click

      view
      |> form("#edit-post-form-#{post.id}", %{post: %{body: "Edited text"}})
      |> render_submit

      assert render(view) =~ "Edited text"
      refute has_element?(view, "#edit-post-form")
    end

    test "Delete a post", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click

      refute has_element?(view, "#delete-post-final-#{post.id}")

      view |> element("#delete-post-link-#{post.id}") |> render_click
      view |> element("#delete-post-final-#{post.id}") |> render_click

      assert render(view) =~ "Post deleted."
      refute has_element?(view, "#delete-post-final-#{post.id}")
    end

    test "Delete a lone reply", %{conn: conn, user: user, board: board} do
      user_2 = user_fixture()
      conn = login_fixture(conn, user)
      post = post_fixture(user_2, board)
      reply = reply_fixture(user, post, "Get rid of me!")
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#last-post-author-link", user.username)
      assert has_element?(view, "#board-post-count", "2")

      view |> element("#board-name", board.name) |> render_click

      assert render(view) =~ "1 reply"
      assert has_element?(view, "#post-#{post.id}-latest-info", user.username)

      view |> element("#post-listing-link", post.title) |> render_click

      assert render(view) =~ "Get rid of me!"

      view |> element("#delete-reply-link-#{reply.id}") |> render_click
      view |> element("#delete-reply-final-#{reply.id}") |> render_click

      # upcoming refutation fails in CI testing otherwise
      Process.sleep(50)

      # Ensure reply was deleted
      refute render(view) =~ "Get rid of me!"

      view |> element("#crumb-board") |> render_click

      assert render(view) =~ "0 replies"
      assert has_element?(view, "#post-#{post.id}-latest-info", user_2.username)

      view |> element("#crumb-index") |> render_click

      # Ensure Board info was updated
      assert has_element?(view, "#last-post-author-link", user_2.username)
      assert has_element?(view, "#board-post-count", "1")
    end

    test "Delete the older of two replies", %{conn: conn, user: user, board: board} do
      user_2 = user_fixture(%{timezone: "Etc/UTC"})
      user_3 = user_fixture()
      conn = login_fixture(conn, user_2)
      post = post_fixture(user, board)
      reply = reply_fixture(user_2, post, "Get rid of me!")
      _reply_2 = reply_fixture(user_3, post, "Keep this reply")
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#last-post-author-link", user_3.username)
      assert has_element?(view, "#board-post-count", "3")

      view |> element("#board-name", board.name) |> render_click

      assert render(view) =~ "2 replies"
      assert has_element?(view, "#post-#{post.id}-latest-info", user_3.username)

      view |> element("#post-listing-link", post.title) |> render_click

      assert render(view) =~ "Get rid of me!"

      view |> element("#delete-reply-link-#{reply.id}") |> render_click
      view |> element("#delete-reply-final-#{reply.id}") |> render_click

      # Ensure reply was deleted
      Process.sleep(50)
      refute render(view) =~ "Get rid of me!"

      view |> element("#crumb-board") |> render_click

      assert render(view) =~ "1 reply"
      assert has_element?(view, "#post-#{post.id}-latest-info", user_3.username)

      view |> element("#crumb-index") |> render_click

      # Ensure Board info was updated
      assert has_element?(view, "#last-post-author-link", user_3.username)
      assert has_element?(view, "#board-post-count", "2")
    end

    test "Delete the newer of two replies", %{conn: conn, user: user, board: board} do
      user_2 = user_fixture()
      user_3 = user_fixture()
      conn = login_fixture(conn, user_3)
      post = post_fixture(user, board)
      _reply = reply_fixture(user_2, post, "Keep this reply")
      reply_2 = reply_fixture(user_3, post, "Get rid of me!")
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#last-post-author-link", user_3.username)
      assert has_element?(view, "#board-post-count", "3")

      view |> element("#board-name", board.name) |> render_click

      assert render(view) =~ "2 replies"
      assert has_element?(view, "#post-#{post.id}-latest-info", user_3.username)

      view |> element("#post-listing-link", post.title) |> render_click

      assert render(view) =~ "Get rid of me!"

      view |> element("#delete-reply-link-#{reply_2.id}") |> render_click
      view |> element("#delete-reply-final-#{reply_2.id}") |> render_click

      # upcoming refutation fails in CI testing otherwise
      Process.sleep(50)

      # Ensure reply was deleted
      refute render(view) =~ "Get rid of me!"

      view |> element("#crumb-board") |> render_click

      assert render(view) =~ "1 reply"
      assert has_element?(view, "#post-#{post.id}-latest-info", user_2.username)

      view |> element("#crumb-index") |> render_click

      # Ensure Board info was updated
      assert has_element?(view, "#last-post-author-link", user_2.username)
      assert has_element?(view, "#board-post-count", "2")
    end

    test "Validate post edits", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)

      {:ok, view, _html} = live(conn, "/")
      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      view |> element("#edit-post-link-#{post.id}") |> render_click
      view |> element("#edit-post-form-#{post.id}") |> render_change(%{post: %{body: "X"}})

      assert has_element?(view, "#edit-post-form-#{post.id}", "should be at least 3 character(s)")

      view |> form("#edit-post-form-#{post.id}", %{post: %{body: "X"}}) |> render_submit

      assert has_element?(view, "#edit-post-form-#{post.id}", "should be at least 3 character(s)")
    end

    test "Validate reply edits", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      reply = reply_fixture(user, post)
      message = "should be at least 3 character(s)"

      {:ok, view, _html} = live(conn, "/")
      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      view |> element("#edit-reply-link-#{reply.id}") |> render_click
      view |> element("#edit-reply-form-#{reply.id}") |> render_change(%{reply: %{body: "X"}})

      assert has_element?(view, "#edit-reply-form-#{reply.id}", message)

      view |> form("#edit-reply-form-#{reply.id}", %{reply: %{body: "X"}}) |> render_submit

      assert has_element?(view, "#edit-reply-form-#{reply.id}", message)
    end

    test "Edit a reply", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      reply = reply_fixture(user, post, "Please edit me!")

      {:ok, view, _html} = live(conn, "/")
      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click

      assert render(view) =~ "Please edit me!"

      view |> element("#edit-reply-link-#{reply.id}") |> render_click

      view
      |> form("#edit-reply-form-#{reply.id}", %{reply: %{body: "Finished editing."}})
      |> render_submit

      refute has_element?(view, "#edit-reply-form")
      assert render(view) =~ "Finished editing."
    end

    test "Cancel a post edit", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      view |> element("#edit-post-link-#{post.id}") |> render_click

      assert has_element?(view, "#edit-post-form-#{post.id}")

      view |> element("#cancel-post-edit-#{post.id}") |> render_click

      refute has_element?(view, "#edit-post-form-#{post.id}")
    end

    test "Cancel a reply edit", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      reply = reply_fixture(user, post, "Please edit me!")
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      view |> element("#edit-reply-link-#{reply.id}") |> render_click

      assert has_element?(view, "#edit-reply-form-#{reply.id}")

      view |> element("#cancel-reply-edit-#{reply.id}") |> render_click

      refute has_element?(view, "#edit-reply-form-#{reply.id}")
    end

    test "Post/reply changes as seen from Main Index", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      _board_2 = Repo.insert!(@board_2)
      post = post_fixture(user, board)
      reply = reply_fixture(user, post, "Test Reply")

      {:ok, view, _html} = live(conn, "/")
      {:ok, view_2, _html} = live(conn, "/")
      view_2 |> element("#board-name", board.name) |> render_click
      view_2 |> element("#post-listing-link", post.title) |> render_click

      # Test reply edit
      view_2 |> element("#edit-reply-link-#{reply.id}") |> render_click

      view_2
      |> form("#edit-reply-form-#{reply.id}", %{reply: %{body: "TESTEDIT"}})
      |> render_submit

      # Test OP edit
      view_2 |> element("#edit-post-link-#{post.id}") |> render_click
      view_2 |> form("#edit-post-form-#{post.id}", %{post: %{body: "POSTEDIT"}}) |> render_submit
      # Test reply delete
      view_2 |> element("#delete-reply-link-#{reply.id}") |> render_click
      view_2 |> element("#delete-reply-final-#{reply.id}") |> render_click

      # upcoming assertion fails in CI testing otherwise
      Process.sleep(50)

      # Original LV is still alive and was updated
      assert has_element?(view, "#main-header")
      assert render(view) =~ "1 post"

      # Board 2 still has not changed
      assert render(view) =~ "No posts yet!"
    end

    test "Post/reply changes as seen from another post", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      _board_2 = Repo.insert!(@board_2)
      post = post_fixture(user, board)
      post_2 = post_fixture(user, board, "Second Post")

      {:ok, view, _html} = live(conn, "/")
      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post_2.title) |> render_click

      {:ok, view_2, _html} = live(conn, "/")
      view_2 |> element("#board-name", board.name) |> render_click
      view_2 |> element("#post-listing-link", post.title) |> render_click

      reply = reply_fixture(user, post)

      # Test reply edit
      view_2 |> element("#edit-reply-link-#{reply.id}") |> render_click

      view_2
      |> form("#edit-reply-form-#{reply.id}", %{reply: %{body: "TESTEDIT"}})
      |> render_submit

      # Test OP edit
      view_2 |> element("#edit-post-link-#{post.id}") |> render_click
      view_2 |> form("#edit-post-form-#{post.id}", %{post: %{body: "POSTEDIT"}}) |> render_submit
      # Test reply delete
      view_2 |> element("#delete-reply-link-#{reply.id}") |> render_click
      view_2 |> element("#delete-reply-final-#{reply.id}") |> render_click

      # Give time for the PubSub message to be received
      Process.sleep(50)

      # Original LV is still alive with no other changes
      assert has_element?(view, "#post-header", post_2.title)
    end

    test "User cache parses IDs from Edit footers", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      reply = reply_fixture(user, post)
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click
      view |> element("#edit-reply-link-#{reply.id}") |> render_click

      view
      |> form("#edit-reply-form-#{reply.id}", %{reply: %{body: "TESTEDIT"}})
      |> render_submit

      view |> element("#edit-post-link-#{post.id}") |> render_click
      view |> form("#edit-post-form-#{post.id}", %{post: %{body: "POSTEDIT"}}) |> render_submit

      {:ok, view, _html} = live(conn, "/?post=#{post.id}")
      assert render(view) =~ "Edited by #{user.username}"
    end

    test "Online users list updates live", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#online-username", user.username)
      refute has_element?(view, "#online-username", "guest")

      diff = %{joins: %{"" => %{metas: [%{name: "guest"}]}}, leaves: %{}}
      send(view.pid, %Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff})

      assert has_element?(view, "#online-username", "guest")

      diff = %{joins: %{}, leaves: %{"" => %{metas: [%{name: "guest"}]}}}
      send(view.pid, %Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff})

      refute has_element?(view, "#online-username", "guest")
    end

    test "Disable and re-enable a user account", %{conn: conn, user: user, board: board} do
      user_2 = user_fixture()
      _user_3 = user_fixture()
      admin_user = user_fixture(%{admin: true})
      admin_conn = login_fixture(conn, admin_user)
      user_conn = login_fixture(conn, user)

      {:ok, user_view, _html} = live(user_conn, "/?board=#{board.id}")
      assert has_element?(user_view, "#new-post-button-top")

      {:ok, admin_view, _html} = live(admin_conn, "/?admin=1")
      assert render(admin_view) =~ "Admin Panel"

      # Test validation first, then submit
      admin_view
      |> form("#admin-disable-user-form")
      |> render_change(%{disable_user: %{user: user.id}})

      admin_view |> element("#disable-user-button") |> render_click

      assert has_element?(admin_view, "#confirm-disable-user")

      admin_view
      |> form("#admin-disable-user-form", %{disable_user: %{user: user.id}})
      |> render_submit

      # Disabling a second user ensures that the "#user-enabled-ok" alert
      # will be visible after re-enabling the first one
      admin_view
      |> form("#admin-disable-user-form", %{disable_user: %{user: user_2.id}})
      |> render_submit

      assert has_element?(admin_view, "#user-disabled-ok")
      admin_view |> element("#user-disabled-ok") |> render_click
      refute has_element?(admin_view, "#user-disabled-ok")

      # Give time for the PubSub messages to be received
      Process.sleep(50)
      refute has_element?(user_view, "#new-post-button-top")

      # Repeat for enabling
      admin_view
      |> form("#admin-enable-user-form")
      |> render_change(%{enable_user: %{user: user.id}})

      admin_view |> element("#enable-user-button") |> render_click

      assert has_element?(admin_view, "#confirm-enable-user")

      admin_view |> form("#admin-enable-user-form") |> render_submit

      assert has_element?(admin_view, "#user-enabled-ok")
      admin_view |> element("#user-enabled-ok") |> render_click
      refute has_element?(admin_view, "#user-enabled-ok")

      Process.sleep(50)
      assert has_element?(user_view, "#new-post-button-top")
    end

    test "Return to board via create_post link", %{conn: conn, user: user, board: board} do
      user_2 = user_fixture()
      post = post_fixture(user_2, board)
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?board=#{board.id}&create_post=1")

      view |> element("#crumb-board") |> render_click

      assert has_element?(view, "#post-listing-link", post.title)
      assert has_element?(view, "#post-author-link", user_2.username)
    end

    test "New topic live validations", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?board=#{board.id}&create_post=1")

      view |> element("#new-topic-form") |> render_change(%{post: %{title: "Test", body: "X"}})

      assert has_element?(view, "#new-topic-form", "should be at least 3 character(s)")
    end

    test "Regular users cannot access Admin Panel", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?admin=1")

      assert has_element?(view, "#page-not-found-live")
    end
  end

  def login_fixture(conn, user) do
    conn
    |> Map.replace!(:secret_key_base, PhxBbWeb.Endpoint.config(:secret_key_base))
    |> init_test_session(%{})
    |> UserAuth.log_in_user(user, %{"remember_me" => "true"})
    |> recycle
  end

  def post_fixture(user, board, title \\ "Test title", body \\ "Test body") do
    {:ok, post} = postmaker(body, title, board.id, user)

    # Update the last post info for the active board
    {1, _} = Boards.added_post(board.id, post.id, user.id)
    # Update the user's post count
    {1, _} = Accounts.added_post(user.id)

    message = {:new_topic, post.author, post.id, post.board_id}
    Phoenix.PubSub.broadcast(PhxBb.PubSub, "posts", message)

    post
  end

  def reply_fixture(user, post, body \\ "Test reply") do
    {:ok, reply} = replymaker(body, post.id, user)

    # Update the last reply info for the active post
    {1, _} = Posts.added_reply(post.id, user.id)
    # Update the last post info for the active board
    {1, _} = Boards.added_reply(post.board_id, post.id, user.id)
    # Update the user's post count
    {1, _} = Accounts.added_post(user.id)

    message = {:new_reply, reply, post.board_id}
    Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

    reply
  end
end
