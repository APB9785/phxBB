defmodule PhxBbWeb.PageLiveTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxBb.AccountsFixtures
  import PhxBbWeb.LiveHelpers

  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Boards.Board
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

  setup do
    %{
      user: user_fixture(%{timezone: "Etc/UTC"}),
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
      alt_user = user_fixture(%{timezone: "Etc/UTC"})
      post = post_fixture(user, board, "First Title")
      alt_post = post_fixture(user, board, "Second Title")
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click

      {:ok, reply} = replymaker("Test reply", alt_post.id, alt_user.id)
      message = {:new_reply, alt_post.id, reply, alt_user.id}
      Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

      # This should run OK but have no visible effect
    end

    test "Visit a board directly from URL", %{conn: conn, board: board} do
      board_link = "/?board=" <> Integer.to_string(board.id)
      {:ok, view, _html} = live(conn, board_link)

      assert has_element?(view, "#board-header", board.name)
    end

    test "Long topic title shortened in Main view", %{conn: conn, user: user, board: board} do
      long_title = String.duplicate("AbcXyz", 20)
      shortened_title = "AbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbc..."
      _post = post_fixture(user, board, long_title)
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#last-post-link", shortened_title)
    end

    test "Post author info box", %{conn: conn, user: user, board: board} do
      post = post_fixture(user, board)
      {:ok, view, _html} = live(conn, "/")

      view |> element("#board-name", board.name) |> render_click
      view |> element("#post-listing-link", post.title) |> render_click

      user_join_date_fragment =
        [user.inserted_at.day, user.inserted_at.year]
        |> Enum.map(&Integer.to_string/1)
        |> Enum.join(", ")

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
      }})
      |> render_submit

      flash = assert_redirected view, "/users/log_in"
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
      }})
      |> render_submit

      assert has_element?(view, "#register-new-user-form", "should be at least 8 character(s)")
    end

    test "Return to Main Index from 404", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?invalid=9999")

      view
      |> element("#return-from-invalid")
      |> render_click

      assert has_element?(view, "#main-header")
    end

    test "Visit a user profile from Main Index", %{conn: conn, user: user, board: board} do
      _post = post_fixture(user, board)

      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#last-post-author-link")
      |> render_click

      assert has_element?(view, "#user-profile-header")
    end

    test "Confirm a user account", %{conn: conn, user: user} do
      token = Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)
      url = "/?confirm=" <> token
      {:ok, conn} = live(conn, url) |> follow_redirect(conn)

      assert html_response(conn, 200) =~ "Account confirmed successfully."
    end

    test "Board updated when navigating between posts", %{conn: conn, user: user, board: board} do
      new_board = Repo.insert!(%Board{
        name: "Sample Topic", description: "Test Board #2",
        post_count: 0, topic_count: 0, last_post: nil, last_user: nil})
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

      # Nothing happens
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

      view
      |> element("#post-listing-link", "Hello World")
      |> render_click

      assert has_element?(view, "#breadcrumb", board.name)
      assert has_element?(view, "#post-header", "Hello World")
      assert has_element?(view, "#new-reply-form")

      # Create a new reply
      view
      |> form("#new-reply-form", %{reply: %{body: "I love Phoenix"}})
      |> render_submit

      assert has_element?(view, "#post-body", "I love Phoenix")
    end

    test "Re-send user confirmation link", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> element("#resend-verification-button")
      |> render_click

      assert has_element?(view, "#confirmation-resent-ok")
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

      assert has_element?(view, "#timezone-update-ok")
    end

    test "Attempt invalid timezone update", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-timezone-form", %{user: %{timezone: "Etc/UTC"}})
      |> render_submit

      assert has_element?(view, "#change-user-timezone-form", "did not change")
    end

    test "Upload and remove user avatar", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
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
          }])

      assert render_upload(avatar, "elixir.png") =~ "100%"

      view
      |> element("#change-user-avatar-form")
      |> render_submit

      view
      |> element("#remove-avatar-link")
      |> render_click

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
          }])

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
          }])

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

      url = "/?create=1&board=" <> Integer.to_string(board.id)
      {:ok, view, _html} = live(conn, url)
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

      view
      |> form("#change-user-avatar-form", %{})
      |> render_submit

      assert has_element?(view, "#avatar-submit-error", "no file was selected")
    end

    test "Reply form live validations", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      url = "/?post=" <> Integer.to_string(post.id)
      {:ok, view, _html} = live(conn, url)

      view
      |> element("#new-reply-form")
      |> render_change(%{reply: %{body: "X"}})

      assert has_element?(view, "#new-reply-form", "should be at least 3 character(s)")
    end

    test "Return to Main Index via breadcrumb", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> element("#crumb-index")
      |> render_click

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
        user:
          %{password: "another pass",
            password_confirmation: "another pass"},
        current_password:
          "hello world!"
      })
      |> render_submit

      flash = assert_redirected view, "/users/log_in"
      assert flash["info"] == "Password updated successfully.  Please log in again."
    end

    test "Failure to change user password", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/?settings=1")

      view
      |> form("#change-user-password-form", %{
        user:
          %{password: "short",
            password_confirmation: "short"},
        current_password:
          "hello world!"
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
      url = "/?board=" <> Integer.to_string(board.id) <> "&create_post=1"
      {:ok, view, _html} = live(conn, url)

      assert has_element?(view, "#new-topic-form")
    end

    test "Fail to create new topic", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      url = "/?board=" <> Integer.to_string(board.id) <> "&create_post=1"
      {:ok, view, _html} = live(conn, url)

      view
      |> form("#new-topic-form", %{post: %{body: "Test body", title: "X"}})
      |> render_submit

      assert has_element?(view, "#new-topic-form", "should be at least 3 character(s)")
    end

    test "Fail to create new reply", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)
      post = post_fixture(user, board)
      url = "/?post=" <> Integer.to_string(post.id)
      {:ok, view, _html} = live(conn, url)

      view
      |> form("#new-reply-form", %{reply: %{body: "OK"}})
      |> render_submit

      assert has_element?(view, "#new-reply-form", "should be at least 3 character(s)")
    end

    test "Confirm a user account", %{conn: conn, user: user} do
      token = Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)
      url = "/?confirm=" <> token
      {:ok, new_conn} = live(conn, url) |> follow_redirect(conn)

      assert html_response(new_conn, 200) =~ "Account confirmed successfully."

      # Log in and try the same confirmation link again
      conn = login_fixture(conn, user)
      {:ok, final_conn} = live(conn, url) |> follow_redirect(conn)

      assert html_response(final_conn, 200) =~ "Welcome to the Forum!"
    end

    test "Confirm an email change", %{conn: conn, user: user} do
      {:ok, applied_user} =
        Accounts.apply_user_email(user, "hello world!", %{email: "newemail@example.com"})
      token =
        Accounts.deliver_update_email_instructions(applied_user, user.email,
          &add_confirm_email_param/1)
      url = "/?confirm_email=" <> token

      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, url) |> follow_redirect(conn)

      assert render(view) =~ "Email changed successfully."
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
    {:ok, post} = postmaker(body, title, board.id, user.id)

    # Update the last post info for the active board
    {1, _} = Boards.added_post(board.id, post.id, user.id)
    # Update the user's post count
    {1, _} = Accounts.added_post(user.id)

    post
  end
end
