defmodule PhxBbWeb.UserProfileComponent do
  @moduledoc """
  Viewing a user's profile.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts

  def update(assigns, socket) do
    posts = Accounts.last_five_posts(assigns.view_user.id)
    socket =
      socket
      |> assign(assigns)
      |> assign(post_history: posts)

    {:ok, socket}
  end
end
