defmodule PhxBbWeb.BoardComponent do
  @moduledoc """
  Board view.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Posts

  def mount(socket) do
    socket = assign(socket, active_post: nil)
    {:ok, socket}
  end

  def update(assigns, socket) do
    posts = Posts.list_posts(assigns.active_board.id)

    cache =
      Enum.reduce(posts, [], fn p, acc -> [p.last_user | [p.author | acc]] end)
      |> Accounts.build_cache(assigns.user_cache)

    socket =
      socket
      |> assign(assigns)
      |> assign(post_list: posts)
      |> assign(user_cache: cache)

    {:ok, socket}
  end
end
