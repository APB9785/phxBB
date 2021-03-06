defmodule PhxBbWeb.LiveHelpers do
  @moduledoc """
  This module contains helper functions to reduce code duplication and increase
  readability within the other LiveView files.
  """

  import Phoenix.LiveView

  alias PhxBb.Accounts.User
  alias PhxBb.Boards
  alias PhxBb.Boards.Board
  alias PhxBb.Posts
  alias PhxBb.Posts.Post
  alias PhxBb.Replies
  alias PhxBbWeb.UserCache

  @month_abv_map %{
    1 => "Jan",
    2 => "Feb",
    3 => "Mar",
    4 => "Apr",
    5 => "May",
    6 => "Jun",
    7 => "Jul",
    8 => "Aug",
    9 => "Sep",
    10 => "Oct",
    11 => "Nov",
    12 => "Dec"
  }

  # Assigns helpers

  def assign_invalid(socket) do
    assign(socket, nav: :invalid, page_title: "404 Page Not Found")
  end

  def assign_post_nav(socket, %Post{} = post) do
    # Increments post view count
    {1, _} = Posts.viewed(post.id)

    socket
    |> assign(nav: :post, page_title: post.title)
    |> check_board_change(post.board_id)
  end

  def assign_post_full_query(socket, post_id) when is_integer(post_id) do
    case Posts.get_post(post_id) do
      nil ->
        assign_invalid(socket)

      %Post{} = post ->
        replies = Replies.list_replies(post.id)
        cache = UserCache.from_topic(post, replies, socket.assigns.user_cache)

        socket
        |> assign(active_post: post, user_cache: cache, reply_list: replies)
        |> assign_post_nav(post)
    end
  end

  def assign_board_full_query(socket, board_id) when is_integer(board_id) do
    case Boards.get_board(board_id) do
      nil ->
        assign_invalid(socket)

      %Board{} = board ->
        post_list = Posts.list_posts(board_id)
        cache = UserCache.from_post_list(post_list, socket.assigns.user_cache)

        assign(socket,
          nav: :board,
          page_title: board.name,
          active_board: board,
          post_list: post_list,
          user_cache: cache
        )
    end
  end

  def assign_create_full_query(socket, board_id) when is_integer(board_id) do
    case Boards.get_board(board_id) do
      nil ->
        assign_invalid(socket)

      %Board{} = board ->
        post_list = Posts.list_posts(board_id)
        cache = UserCache.from_post_list(post_list, socket.assigns.user_cache)

        assign(socket,
          nav: :create_post,
          page_title: "Create Post",
          active_board: board,
          post_list: post_list,
          user_cache: cache
        )
    end
  end

  def assign_defaults(socket) do
    assign(socket,
      active_board: nil,
      active_post: nil,
      board_list: Boards.list_boards(),
      users_online: %{},
      post_list: []
    )
  end

  # Query the database for Board data only if the active Board has changed.
  def check_board_change(socket, new_board_id) when is_integer(new_board_id) do
    active_board = socket.assigns[:active_board]

    if is_nil(active_board) or active_board.id != new_board_id do
      post_list = Posts.list_posts(new_board_id)

      assign(socket,
        active_board: Boards.get_board!(new_board_id),
        post_list: post_list,
        user_cache: UserCache.from_post_list(post_list, socket.assigns.user_cache)
      )
    else
      socket
    end
  end

  def active_assign_outdated?(assign, target_id, socket) when is_integer(target_id) do
    active =
      case assign do
        :post -> socket.assigns.active_post
        :board -> socket.assigns.active_board
      end

    is_nil(active) or target_id != active.id
  end

  # Redirect helpers

  def user_confirm_error_redirect(socket) do
    case socket.assigns do
      %{active_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        redirect(socket, to: "/")

      %{} ->
        socket
        |> put_flash(:error, "Account confirmation link is invalid or it has expired.")
        |> redirect(to: "/")
    end
  end

  # Date/Time stamp

  defp month_abv(n) do
    Map.get(@month_abv_map, n)
  end

  def format_date(naive_datetime, user) when is_nil(user) do
    format_date(naive_datetime)
  end

  def format_date(naive_datetime, user) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(user.timezone)
    |> format_date
  end

  def format_date(datetime) do
    day = Integer.to_string(datetime.day)
    month = month_abv(datetime.month)
    year = Integer.to_string(datetime.year)

    [month, " ", day, ", ", year]
  end

  def format_time(naive_datetime, user) when is_nil(user) do
    format_time(naive_datetime)
  end

  def format_time(naive_datetime, user) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(user.timezone)
    |> format_time
  end

  def format_time(datetime) do
    month = month_abv(datetime.month)
    minute = Integer.to_string(datetime.minute) |> String.pad_leading(2, "0")
    ampm = if datetime.hour > 11, do: "pm", else: "am"
    day = Integer.to_string(datetime.day)
    year = Integer.to_string(datetime.year)

    hour =
      case datetime.hour do
        0 -> "12"
        x when x > 12 -> Integer.to_string(x - 12)
        x -> Integer.to_string(x)
      end

    [month, " ", day, ", ", year, "  ", hour, ":", minute, " ", ampm]
  end

  # Display

  def shortener(text) do
    case String.slice(text, 0..45) do
      ^text -> text
      short -> [short, "..."]
    end
  end

  def replace_error(changeset, key, message, keys \\ []) when is_binary(message) do
    %{changeset | errors: [{key, {message, keys}}], valid?: false}
  end

  # Post + Reply

  def postmaker(body, title, board_id, %User{disabled_at: nil, id: user_id}) do
    %{body: body, title: title, board_id: board_id, author: user_id, last_user: user_id}
    |> PhxBb.Posts.create_post()
  end

  def postmaker(_, _, _, _), do: {:disabled}

  def replymaker(body, post_id, %User{disabled_at: nil, id: user_id}) do
    %{body: body, post_id: post_id, author: user_id}
    |> PhxBb.Replies.create_reply()
  end

  def replymaker(_, _, _), do: {:disabled}

  # URL makers

  def add_confirm_param(token) do
    PhxBbWeb.Endpoint.url() <> "?confirm=" <> token
  end

  def add_confirm_email_param(token) do
    PhxBbWeb.Endpoint.url() <> "?confirm_email=" <> token
  end

  def admin?(nil), do: false
  def admin?(%User{} = user), do: user.admin

  def disabled?(nil), do: false
  def disabled?(%User{disabled_at: time}), do: !is_nil(time)

  def author?(nil, _), do: false
  def author?(%User{} = user, post), do: user.id == post.author

  def parse_post_body(content) do
    content
    |> Earmark.as_html!()
    |> PhoenixHtmlSanitizer.Helpers.sanitize(:markdown_html)
  end

  def id_maker(action, type, element, content_id) do
    content_id = Integer.to_string(content_id)
    [action, type, element, content_id] |> Enum.join("-")
  end

  def guest_id, do: 0 - System.unique_integer([:positive])
end
