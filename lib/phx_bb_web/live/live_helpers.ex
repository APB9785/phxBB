defmodule PhxBbWeb.LiveHelpers do
  def current_user_id(socket) do
    PhxBb.Accounts.get_user_by_session_token(socket.assigns.user_token).id
  end

  def lookup_token(token) when is_nil(token) do
    nil
  end
  def lookup_token(token) do
    PhxBb.Accounts.get_user_by_session_token(token)
  end

  def user_form do
    "mb-4 appearance-none w-full border-purple-300 rounded-md transition duration-150 text-sm focus:outline-none focus:ring focus:ring-purple-300 focus:border-purple-300"
  end

  def user_form_label do
    "block my-2 text-sm font-medium text-gray-600"
  end

  def user_menu do
    "py-2 max-w-sm mx-auto rounded-xl shadow-md antialiased relative opacity-100 font-sans bg-gray-100"
  end

  def button_style do
    "px-8 py-2 mt-4 mb-4 w-6/12 md:w-3/12 rounded-md bg-purple-700 text-white"
  end

  defp month_abv(n) do
    case n do
      1 -> "Jan"
      2 -> "Feb"
      3 -> "Mar"
      4 -> "Apr"
      5 -> "May"
      6 -> "Jun"
      7 -> "Jul"
      8 -> "Aug"
      9 -> "Sep"
      10 -> "Oct"
      11 -> "Nov"
      12 -> "Dec"
    end
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
    month_abv(datetime.month) <> " " <> Integer.to_string(datetime.day) <>
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
    ampm = if datetime.hour > 11 do "pm" else "am" end
    hour =
      case datetime.hour do
        0 -> "12"
        x when x > 12 -> Integer.to_string(x - 12)
        x -> Integer.to_string(x)
      end
    minute = Integer.to_string(datetime.minute) |> String.pad_leading(2, "0")

    month <> " " <> Integer.to_string(datetime.day) <> ", " <>
      Integer.to_string(datetime.year) <> "  " <> hour <> ":" <> minute <> " " <> ampm
  end

  def shortener(text) do
    case String.slice(text, 0..50) do
      ^text -> text
      short -> short <> "..."
    end
  end

  def display_title(post) do
    post
    |> PhxBb.Posts.get_title
    |> shortener
  end

  def postmaker(body, title, board_id, user_id) do
    %{body: body, title: title, board_id: board_id, author: user_id, last_user: user_id}
    |> PhxBb.Posts.create_post
  end

  def replymaker(body, post_id, user_id) do
    %{body: body, post_id: post_id, author: user_id}
    |> PhxBb.Replies.create_reply
  end

  def assign_timezone(socket) do
    socket
  end
end
