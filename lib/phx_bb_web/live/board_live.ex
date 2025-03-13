defmodule PhxBbWeb.BoardLive do
  @moduledoc """
  LiveView to display a board and its topics.
  """
  use PhxBbWeb, :live_view

  alias PhxBb.Accounts.User
  alias PhxBb.Topics
  alias PhxBb.Topics.Topic
  alias PhxBbWeb.{Endpoint, ForumLive, StyleHelpers, Timestamps}

  def mount(_params, session, socket) do
    if connected?(socket), do: send(socket.parent_pid, {:child_pid, self()})

    board = session["active_board"]
    user = session["current_user"]
    page = 1
    topics = PhxBb.Topics.list_topics(board.id, page, user)

    Phoenix.PubSub.subscribe(PhxBb.PubSub, "board:#{board.id}")

    socket =
      assign(socket,
        page: page,
        update_toggle: "append",
        topic_list: topics,
        topic_queue: [],
        active_board: board,
        current_user: user
      )

    {:ok, socket, temporary_assigns: [topic_list: []]}
  end

  def handle_event("load_more", _params, socket) do
    new_page = socket.assigns.page + 1
    board = socket.assigns.active_board
    user = socket.assigns.current_user
    topics = Topics.list_topics(board.id, new_page, user)

    {:noreply, assign(socket, update_toggle: "append", page: new_page, topic_list: topics)}
  end

  def handle_event("update", _params, %{assigns: %{topic_queue: queue}} = socket) do
    {:noreply, assign(socket, update_toggle: "prepend", topic_list: queue, topic_queue: [])}
  end

  def handle_info({:new_topic, topic}, %{assigns: %{current_user: user}} = socket) do
    if is_nil(user) or user.id == topic.author.id do
      {:noreply, socket}
    else
      topic = Topics.load_seen_at(topic, user)
      {:noreply, update(socket, :topic_queue, &[topic | &1])}
    end
  end

  def handle_info({:updated_user, user}, socket) do
    {:noreply, assign(socket, current_user: user)}
  end

  def link_to_topic(%Topic{title: title, id: id} = topic, current_user) do
    live_patch(title,
      to: Routes.live_path(Endpoint, ForumLive, topic: id),
      class: topic_link_style(current_user, topic),
      phx_hook: "ScrollToTop",
      id: "topic-listing-link-#{id}"
    )
  end

  def link_to_author(%Topic{author: author, id: id}, current_user) do
    live_patch(author.username,
      to: Routes.live_path(Endpoint, ForumLive, user: author),
      class: StyleHelpers.link_style(current_user),
      phx_hook: "ScrollToTop",
      id: "topic-author-link-#{id}"
    )
  end

  def link_to_recent_user(%Topic{recent_user: recent_user, id: id}, current_user) do
    live_patch(recent_user.username,
      to: Routes.live_path(Endpoint, ForumLive, user: recent_user),
      class: StyleHelpers.link_style(current_user),
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
