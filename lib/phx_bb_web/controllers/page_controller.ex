defmodule PhxBbWeb.PageController do
  use PhxBbWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
