defmodule PhxBbWeb.PageLiveTest do
  use PhxBbWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Welcome to the Forum!"
    assert render(page_live) =~ "Welcome to the Forum!"
  end
end
