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

  # test "disconnected and connected render", %{conn: conn} do
  #   {:ok, page_live, disconnected_html} = live(conn, "/")
  #   assert disconnected_html =~ "Welcome to the Forum!"
  #   assert render(page_live) =~ "Welcome to the Forum!"
  # end

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
      {:ok, post} = postmaker("Test body", "Test title", board.id, user.id)
      # Update the last post info for the active board
      {1, _} = Boards.added_post(board.id, post.id, user.id)
      # Update the user's post count
      {1, _} = Accounts.added_post(user.id)

      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#board-name", board.name)
      assert has_element?(view, "#board-description", board.description)
      assert has_element?(view, "#board-topic-count", "1 topic")
      assert has_element?(view, "#board-post-count", "1 post")
      assert has_element?(view, "#last-post-by", user.username)
      assert has_element?(view, "#last-post-link", "Test title")
    end

    test "Long topic title shortened in Main view", %{conn: conn, user: user, board: board} do
      long_title = String.duplicate("AbcXyz", 20)
      shortened_title = "AbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbcXyzAbc..."
      {:ok, long_post} = postmaker("Test body", long_title, board.id, user.id)
      {1, _} = Boards.added_post(board.id, long_post.id, user.id)
      {1, _} = Accounts.added_post(user.id)
      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#last-post-link", shortened_title)
    end

    test "Navigation and viewing posts", %{conn: conn, user: user, board: board} do
      {:ok, post} = postmaker("Test body", "Test title", board.id, user.id)
      # Update the last post info for the active board
      {1, _} = Boards.added_post(board.id, post.id, user.id)
      # Update the user's post count
      {1, _} = Accounts.added_post(user.id)

      {:ok, view, _html} = live(conn, "/")

      # Navigate to Board
      view
      |> element("#board-name", board.name)
      |> render_click

      assert has_element?(view, "#breadcrumb", "Board Index")
      assert has_element?(view, "#board-header", board.name)
      assert has_element?(view, "#post-listing", "Test title")

      # Navigate to Post
      view
      |> element("#post-listing-link", "Test title")
      |> render_click

      user_join_date_fragment =
        [user.inserted_at.day, user.inserted_at.year]
        |> Enum.map(&Integer.to_string/1)
        |> Enum.join(", ")

      assert has_element?(view, "#post-header", "Test title")
      assert has_element?(view, "#post-author-info", user.username)
      assert has_element?(view, "#post-author-info", user.title)
      assert has_element?(view, "#author-post-count", "1")
      assert has_element?(view, "#author-join-date", user_join_date_fragment)
    end

    test "Invalid confirmation tokens", %{conn: conn} do
      live(conn, "/?confirm=123456789")
      |> follow_redirect(conn, "/")
      live(conn, "/?confirm_email=123456789")
      |> follow_redirect(conn, "/")
    end

    test "Visit pages which require login", %{conn: conn} do
      # Visit pages which require login
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

    test "Return to Main Index from 404", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?invalid=9999")

      view
      |> element("#return-from-invalid")
      |> render_click

      assert has_element?(view, "#main-header")
    end

    test "Open Register User dialog", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#user-menu-register")
      |> render_click

      assert has_element?(view, "#register-header")
    end

    test "Visit a user profile from Main Index", %{conn: conn, user: user, board: board} do
      {:ok, post} = postmaker("Test body", "Test title", board.id, user.id)
      # Update the last post info for the active board
      {1, _} = Boards.added_post(board.id, post.id, user.id)
      # Update the user's post count
      {1, _} = Accounts.added_post(user.id)

      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#last-post-author-link")
      |> render_click

      assert has_element?(view, "#user-profile-header")
    end
  end

  describe "Logged-in User:" do
    test "Create a new topic and reply", %{conn: conn, user: user, board: board} do
      conn = login_fixture(conn, user)

      {:ok, view, _html} = live(conn, "/")

      assert has_element?(view, "#logged-in-menu", user.username)

      view
      |> element("#board-name", board.name)
      |> render_click

      view
      |> element("#new-post-button")
      |> render_click

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

    test "Update user title", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#user-menu-settings") |> render_click

      {:ok, view, _html} =
        view
        |> form("#change-user-title-form", %{user: %{title: "Expert"}})
        |> render_submit
        |> follow_redirect(conn)

      assert has_element?(view, "[role=alert]", "User title updated successfully.")
    end

    test "Attempt invalid user title update", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#user-menu-settings") |> render_click

      view
      |> form("#change-user-title-form", %{user: %{title: "abcdefghijklmnopqrstuvwxyz"}})
      |> render_submit

      assert has_element?(view, "#change-user-title-form", "should be at most")
    end

    test "Update user timezone", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#user-menu-settings") |> render_click

      {:ok, view, _html} =
        view
        |> form("#change-user-timezone-form", %{user: %{timezone: "US/Central"}})
        |> render_submit
        |> follow_redirect(conn)

      assert has_element?(view, "[role=alert]", "Timezone updated successfully.")
    end

    test "Attempt invalid timezone update", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#user-menu-settings") |> render_click

      view
      |> form("#change-user-timezone-form", %{user: %{timezone: "Etc/UTC"}})
      |> render_submit

      assert has_element?(view, "#change-user-timezone-form", "did not change")
    end

    test "Change user avatar", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#user-menu-settings") |> render_click

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
    end

    test "Attempt to change avatar with no file selected", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#user-menu-settings") |> render_click

      view
      |> form("#change-user-avatar-form", %{})
      |> render_submit

      assert has_element?(view, "#avatar-submit-error", "no file was selected")
    end

    test "Return to Main Index via breadcrumb", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#user-menu-settings") |> render_click

      view
      |> element("#crumb-index")
      |> render_click

      assert has_element?(view, "#main-header")
    end

    test "Create new topic in nonexistent board", %{conn: conn, user: user} do
      conn = login_fixture(conn, user)

      {:ok, view, _html} = live(conn, "/?board=9999&create_post=1")
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
end
