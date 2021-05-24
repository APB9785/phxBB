defmodule PhxBbWeb.LiveHelpersTest do
  use PhxBbWeb.ConnCase

  import PhxBbWeb.LiveHelpers

  alias PhxBb.Accounts.User

  test "format_time/1" do
    datetime = %NaiveDateTime{
      month: 2,
      day: 3,
      year: 1980,
      hour: 10,
      minute: 11,
      second: 5
    }

    assert format_time(datetime) == "Feb 3, 1980  10:11 am"
    assert format_time(%{datetime | hour: 13}) == "Feb 3, 1980  1:11 pm"
  end

  test "postmaker/4" do
    now = NaiveDateTime.utc_now()
    assert postmaker("test body", "test title", 1, %User{disabled_at: now}) == {:disabled}
  end

  test "replymaker/3" do
    now = NaiveDateTime.utc_now()
    assert replymaker("test body", 1, %User{disabled_at: now}) == {:disabled}
  end
end
