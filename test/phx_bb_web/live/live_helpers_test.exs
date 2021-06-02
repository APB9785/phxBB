defmodule PhxBbWeb.LiveHelpersTest do
  use PhxBbWeb.ConnCase

  import PhxBb.AccountsFixtures, only: [user_fixture: 1]
  import PhxBbWeb.LiveHelpers, only: [format_time: 1, postmaker: 4, replymaker: 3]
  import PhxBbWeb.StyleHelpers, only: [post_form_theme: 1, confirmation_reminder_theme: 1]

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

    assert format_time(datetime) |> IO.iodata_to_binary() == "Feb 3, 1980  10:11 am"
    assert format_time(%{datetime | hour: 13}) |> IO.iodata_to_binary() == "Feb 3, 1980  1:11 pm"
  end

  test "postmaker/4" do
    now = NaiveDateTime.utc_now()
    assert postmaker("test body", "test title", 1, %User{disabled_at: now}) == {:disabled}
  end

  test "replymaker/3" do
    now = NaiveDateTime.utc_now()
    assert replymaker("test body", 1, %User{disabled_at: now}) == {:disabled}
  end

  test "StyleHelpers.post_form_theme/1" do
    user = user_fixture(%{theme: "default"})
    assert post_form_theme(nil) == post_form_theme(user)
  end

  test "StyleHelpers.confirmation_reminder_theme/1" do
    user = user_fixture(%{theme: "default"})
    assert confirmation_reminder_theme(nil) == confirmation_reminder_theme(user)
  end
end
