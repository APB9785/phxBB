defmodule PhxBbWeb.PostComponent do
  @moduledoc """
  View a post and its replies.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Replies

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    replies = Replies.list_replies(assigns.active_post.id)
    user_ids = Enum.map(replies, fn reply -> reply.author end)
    cache = Accounts.build_cache([assigns.active_post.author | user_ids], assigns.user_cache)

    socket =
      socket
      |> assign(assigns)
      |> assign([user_cache: cache, reply_list: replies])

    {:ok, socket}
  end
end
