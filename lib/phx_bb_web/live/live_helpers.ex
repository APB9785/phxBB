defmodule PhxBbWeb.LiveHelpers do
  def current_user_id(socket) do
    PhxBb.Accounts.get_user_by_session_token(socket.assigns.user_token).id
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

  def format_date(ndt) do
    date = NaiveDateTime.to_date(ndt)
    month_abv(date.month) <> " " <> Integer.to_string(date.day) <>
      ", " <> Integer.to_string(date.year)
  end

  def format_time(ndt) do
    month = month_abv(ndt.month)
    ampm = if ndt.hour > 11 do "pm" else "am" end
    hour =
      case ndt.hour do
        0 -> "12"
        x when x > 12 -> Integer.to_string(x - 12)
        x -> Integer.to_string(x)
      end
    minute = Integer.to_string(ndt.minute) |> String.pad_leading(2, "0")

    month <> " " <> Integer.to_string(ndt.day) <> ", " <>
      Integer.to_string(ndt.year) <> "  " <> hour <> ":" <> minute <> " " <> ampm
  end

  def format_time(ndt, offset) do
    ndt
    |> NaiveDateTime.add(offset * 3600)
    |> format_time
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
end
