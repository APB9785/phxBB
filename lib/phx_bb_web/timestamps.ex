defmodule PhxBbWeb.Timestamps do
  @moduledoc """
  This module contains functions for formatting Dates and DateTimes.
  """

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
end
