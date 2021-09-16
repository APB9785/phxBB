defmodule PhxBbWeb.UserProfile do
  @moduledoc """
  Viewing a user's profile.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Posts.Post
  alias PhxBbWeb.{Endpoint, ForumLive, Parsers, StyleHelpers, Timestamps}

  def update(assigns, socket) do
    posts = PhxBb.Accounts.last_five_posts(assigns.view_user.id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(post_history: posts)}
  end

  def link_to_topic(%Post{topic: topic, id: post_id}, active_user) do
    live_patch(Parsers.shortener(topic.title),
      to: Routes.live_path(Endpoint, ForumLive, topic: topic.id),
      class: StyleHelpers.link_style(active_user),
      phx_hook: "ScrollToTop",
      id: "post-#{post_id}-link"
    )
  end

  ## Tailwind Styles

  def user_history_bubble_style(user) do
    [
      "p-2 pb-4 pr-4 rounded-xl w-max max-w-full md:max-w-prose shadow-md md:mx-8 ",
      StyleHelpers.content_bubble_theme(user)
    ]
  end

  def user_history_timestamp_style(user),
    do: ["text-sm w-40 pb-2 ", StyleHelpers.timestamp_theme(user)]
end
