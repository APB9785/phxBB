defmodule PhxBbWeb.LiveHelpers do
  @moduledoc """
  This module contains helper functions to reduce code duplication and increase
  readability within the other LiveView files.
  """

  import Phoenix.LiveView

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBb.Boards
  alias PhxBb.Boards.Board
  alias PhxBb.Posts
  alias PhxBb.Posts.Post
  alias PhxBb.Replies

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

  def lookup_token(token) when is_nil(token) do
    nil
  end

  def lookup_token(token) do
    PhxBb.Accounts.get_user_by_session_token(token)
  end

  # Assigns helpers

  def assign_invalid(socket) do
    assign(socket, nav: :invalid, page_title: "404 Page Not Found")
  end

  def assign_post_nav(socket, post) do
    # Increments post view count
    {1, _} = Posts.viewed(post.id)

    socket
    |> assign(nav: :post, page_title: post.title)
    |> check_board_change(post.board_id)
  end

  def assign_post_full_query(socket, post_id) do
    case Posts.get_post(post_id) do
      nil ->
        assign_invalid(socket)

      post ->
        replies = Replies.list_replies(post.id)
        user_ids = parse_user_ids(replies, post)
        cache = Accounts.build_cache(user_ids, socket.assigns.user_cache)

        socket
        |> assign_post_nav(post)
        |> assign(active_post: post, user_cache: cache, reply_list: replies)
    end
  end

  defp parse_user_ids(replies, post) do
    user_ids =
      Enum.reduce(replies, [], fn reply, acc ->
        case reply.edited_by do
          nil -> [reply.author | acc]
          editor -> [reply.author | [editor | acc]]
        end
      end)

    case post.edited_by do
      nil -> [post.author | user_ids]
      editor -> [post.author | [editor | user_ids]]
    end
  end

  def assign_board_full_query(socket, board_id) do
    case Boards.get_board(board_id) do
      nil ->
        assign_invalid(socket)

      board ->
        assign(socket, nav: :board, page_title: board.name, active_board: board)
    end
  end

  def assign_create_full_query(socket, board_id) do
    case Boards.get_board(board_id) do
      nil ->
        assign_invalid(socket)

      board ->
        assign(socket, nav: :create_post, page_title: "Create Post", active_board: board)
    end
  end

  def assign_defaults(socket) do
    boards = Boards.list_boards()

    assign(socket,
      active_board: nil,
      active_post: nil,
      board_list: boards,
      users_online: %{}
    )
  end

  # Query the database for Board data only if the active Board has changed.
  def check_board_change(socket, new_board_id) do
    case socket.assigns[:active_board] do
      nil ->
        assign(socket, active_board: Boards.get_board!(new_board_id))

      %Board{id: current_id} when current_id != new_board_id ->
        assign(socket, active_board: Boards.get_board!(new_board_id))

      %Board{} ->
        socket
    end
  end

  def active_assign_outdated?(assign, target_id, socket) do
    active =
      case assign do
        :post -> socket.assigns.active_post
        :board -> socket.assigns.active_board
      end

    is_nil(active) or String.to_integer(target_id) != active.id
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
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")

    DateTime.shift_zone!(datetime, user.timezone)
    |> format_date
  end

  def format_date(datetime) do
    month_abv(datetime.month) <>
      " " <>
      Integer.to_string(datetime.day) <>
      ", " <> Integer.to_string(datetime.year)
  end

  def format_time(naive_datetime, user) when is_nil(user) do
    format_time(naive_datetime)
  end

  def format_time(naive_datetime, user) do
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")

    DateTime.shift_zone!(datetime, user.timezone)
    |> format_time
  end

  def format_time(datetime) do
    month = month_abv(datetime.month)

    ampm =
      if datetime.hour > 11 do
        "pm"
      else
        "am"
      end

    hour =
      case datetime.hour do
        0 -> "12"
        x when x > 12 -> Integer.to_string(x - 12)
        x -> Integer.to_string(x)
      end

    minute = Integer.to_string(datetime.minute) |> String.pad_leading(2, "0")

    month <>
      " " <>
      Integer.to_string(datetime.day) <>
      ", " <>
      Integer.to_string(datetime.year) <> "  " <> hour <> ":" <> minute <> " " <> ampm
  end

  # Display

  def shortener(text) do
    case String.slice(text, 0..45) do
      ^text -> text
      short -> short <> "..."
    end
  end

  def display_title(post) do
    post
    |> PhxBb.Posts.get_title()
    |> shortener
  end

  def replace_error(changeset, key, message, keys \\ []) when is_binary(message) do
    %{changeset | errors: [{key, {message, keys}}], valid?: false}
  end

  def topic_count_display(%Board{topic_count: 1}), do: "1 topic"

  def topic_count_display(%Board{topic_count: count}) do
    Integer.to_string(count) <> " topics"
  end

  def post_count_display(%Board{post_count: 1}), do: "1 post"

  def post_count_display(%Board{post_count: count}) do
    Integer.to_string(count) <> " posts"
  end

  def view_count_display(%Post{view_count: 1}), do: "1 view"

  def view_count_display(%Post{view_count: count}) do
    Integer.to_string(count) <> " views"
  end

  def reply_count_display(%Post{reply_count: 1}), do: "1 reply"

  def reply_count_display(%Post{reply_count: count}) do
    Integer.to_string(count) <> " replies"
  end

  # Post + Reply

  def postmaker(body, title, board_id, user_id) do
    %{body: body, title: title, board_id: board_id, author: user_id, last_user: user_id}
    |> PhxBb.Posts.create_post()
  end

  def replymaker(body, post_id, user_id) do
    %{body: body, post_id: post_id, author: user_id}
    |> PhxBb.Replies.create_reply()
  end

  # URL makers

  def add_confirm_param(token) do
    PhxBbWeb.Endpoint.url() <> "?confirm=" <> token
  end

  def add_confirm_email_param(token) do
    PhxBbWeb.Endpoint.url() <> "?confirm_email=" <> token
  end

  def display_avatar_error({:avatar, {error, _}}), do: error

  def filename(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end

  def no_file_error(socket) do
    replace_error(socket.assigns.avatar_changeset, :avatar, "no file was selected")
  end

  def cache_self(%User{} = user) do
    %{
      name: user.username,
      joined: user.inserted_at,
      title: user.title,
      avatar: user.avatar,
      post_count: user.post_count
    }
  end

  def admin?(nil), do: false
  def admin?(user), do: user.admin

  def author?(nil, _), do: false
  def author?(user, post), do: user.id == post.author

  def parse_post_body(content) do
    content
    |> Earmark.as_html!()
    |> PhoenixHtmlSanitizer.Helpers.sanitize(:markdown_html)
  end

  def id_maker(action, type, element, content_id) do
    content_id = Integer.to_string(content_id)
    [action, type, element, content_id] |> Enum.join("-")
  end
end
