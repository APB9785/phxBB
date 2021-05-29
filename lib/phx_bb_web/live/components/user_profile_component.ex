defmodule PhxBbWeb.UserProfileComponent do
  @moduledoc """
  Viewing a user's profile.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers,
    only: [format_date: 2, shortener: 1, format_time: 2, parse_post_body: 1]

  import PhxBbWeb.StyleHelpers,
    only: [link_style: 1, user_history_bubble_style: 1, user_history_timestamp_style: 1]

  def update(assigns, socket) do
    posts = PhxBb.Accounts.last_five_posts(assigns.view_user.id)
    {:ok, socket |> assign(assigns) |> assign(post_history: posts)}
  end
end
