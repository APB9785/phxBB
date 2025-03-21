defmodule PhxBbWeb.TimestampsTest do
  use PhxBbWeb.ConnCase

  alias PhxBbWeb.Timestamps

  test "format_time/1" do
    datetime = %DateTime{
      month: 2,
      day: 3,
      year: 1980,
      hour: 10,
      minute: 11,
      second: 5
    }

    res = Timestamps.format_time(datetime)
    assert IO.iodata_to_binary(res) == "Feb 3, 1980  10:11 am"

    res = Timestamps.format_time(%{datetime | hour: 13})
    assert IO.iodata_to_binary(res) == "Feb 3, 1980  1:11 pm"
  end
end
