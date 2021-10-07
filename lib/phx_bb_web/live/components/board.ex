defmodule PhxBbWeb.Board do
  @moduledoc """
  Board view.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBb.Topics
  alias PhxBb.Topics.Topic
  alias PhxBbWeb.{Endpoint, ForumLive, StyleHelpers, Timestamps}

  def mount(socket) do
    {:ok, assign(socket, page: 1), temporary_assigns: [topic_list: []]}
  end

  def update(assigns, socket) do
    board = assigns.active_board
    user = assigns.active_user
    page = socket.assigns.page
    topics = PhxBb.Topics.list_topics(board.id, page, user)

    {:ok, assign(socket, topic_list: topics, active_user: user, active_board: board)}
  end

  def link_to_topic(%Topic{title: title, id: id} = topic, active_user) do
    live_patch(title,
      to: Routes.live_path(Endpoint, ForumLive, topic: id),
      class: topic_link_style(active_user, topic),
      phx_hook: "ScrollToTop",
      id: "topic-listing-link-#{id}"
    )
  end

  def link_to_author(%Topic{author: author, id: id}, active_user) do
    live_patch(author.username,
      to: Routes.live_path(Endpoint, ForumLive, user: author),
      class: StyleHelpers.link_style(active_user),
      phx_hook: "ScrollToTop",
      id: "topic-author-link-#{id}"
    )
  end

  def link_to_recent_user(%Topic{recent_user: recent_user, id: id}, active_user) do
    live_patch(recent_user.username,
      to: Routes.live_path(Endpoint, ForumLive, user: recent_user),
      class: StyleHelpers.link_style(active_user),
      phx_hook: "ScrollToTop",
      id: "topic-recent-user-link-#{id}"
    )
  end

  def new_topic_button(board_id, user) do
    live_patch("New Topic",
      to: Routes.live_path(Endpoint, ForumLive, board: board_id, create_topic: 1),
      class: new_post_button_style(user),
      id: "new-topic-button"
    )
  end

  def handle_event("load_more", _params, socket) do
    new_page = socket.assigns.page + 1
    board = socket.assigns.active_board
    user = socket.assigns.active_user
    topics = PhxBb.Topics.list_topics(board.id, new_page, user)
    {:noreply, assign(socket, page: new_page, topic_list: topics)}
  end

  def view_count_display(%Topic{view_count: 1}), do: "1 view"
  def view_count_display(%Topic{view_count: count}), do: "#{count} views"

  def post_count_display(%Topic{post_count: 1}), do: "1 post"
  def post_count_display(%Topic{post_count: count}), do: "#{count} posts"

  def may_create_topic?(user), do: !is_nil(user) and is_nil(user.disabled_at)

  ## Tailwind Styles

  def new_post_button_style(user),
    do: ["px-8 py-2 justify-center rounded-md text-sm ", StyleHelpers.button_theme(user)]

  def post_dividers(nil), do: post_dividers(%User{theme: StyleHelpers.default()})
  def post_dividers(%User{theme: "elixir"}), do: "md:border-t-2 md:border-b-2 md:divide-y-2"

  def post_dividers(%User{theme: "dark"}) do
    "md:border-t-2 md:border-b-2 md:divide-y-2 md:border-gray-500 md:divide-gray-500"
  end

  def topic_bubble_style(user) do
    [
      "p-4 block items-center rounded-lg m-1 ",
      "md:flex md:m-0 md:bg-transparent md:rounded-none ",
      StyleHelpers.content_bg_theme(user)
    ]
  end

  def topic_link_style(user, topic) do
    greyed = if Topics.up_to_date?(topic), do: " text-gray-600", else: ""

    [StyleHelpers.link_style(user), greyed]
  end
end
