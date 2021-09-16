defmodule PhxBbWeb.MainIndex do
  @moduledoc """
  Main Index.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBb.Boards.Board
  alias PhxBbWeb.{Endpoint, ForumLive, Parsers, StyleHelpers}

  def mount(socket) do
    {:ok, assign(socket, board_list: PhxBb.Boards.list_boards())}
  end

  def topic_count_display(%Board{topic_count: 1}), do: "1 topic"
  def topic_count_display(%Board{topic_count: count}), do: "#{count} topics"

  def post_count_display(%Board{post_count: 1}), do: "1 post"
  def post_count_display(%Board{post_count: count}), do: "#{count} posts"

  ## Navigation

  def link_to_board(%Board{name: name, id: id}, user) do
    live_patch(name,
      to: Routes.live_path(Endpoint, ForumLive, board: id),
      class: ["hover:underline font-bold text-lg ", StyleHelpers.text_theme(user)],
      phx_hook: "ScrollToTop",
      id: "board-#{id}-link"
    )
  end

  def link_to_recent_user(%Board{recent_user: recent_user, id: id}, active_user) do
    live_patch(recent_user.username,
      to: Routes.live_path(Endpoint, ForumLive, user: recent_user.id),
      class: StyleHelpers.link_style(active_user),
      phx_hook: "ScrollToTop",
      id: "board-#{id}-recent-author-link"
    )
  end

  def link_to_recent_topic(%Board{recent_topic: topic, id: id}, user) do
    live_patch(Parsers.shortener(topic.title),
      to: Routes.live_path(Endpoint, ForumLive, topic: topic),
      class: StyleHelpers.link_style(user),
      phx_hook: "ScrollToTop",
      id: "board-#{id}-recent-topic-link"
    )
  end

  ## Tailwind styles

  def board_stats_style(user), do: [board_stats_base(), " ", board_stats_theme(user)]

  defp board_stats_base do
    "pl-4 pt-2 text-sm border-t flex md:p-4 md:text-base md:grid md:border-0 md:w-1/12 md:content-evenly"
  end

  defp board_stats_theme(nil), do: board_stats_theme(%User{theme: StyleHelpers.default()})
  defp board_stats_theme(%User{theme: "elixir"}), do: "border-gray-300"
  defp board_stats_theme(%User{theme: "dark"}), do: "border-gray-500"

  def index_board_bubble_style(user) do
    [
      "rounded-lg m-1 md:bg-transparent md:rounded-t-none md:flex md:m-0 ",
      index_board_bubble_theme(user)
    ]
  end

  defp index_board_bubble_theme(nil),
    do: index_board_bubble_theme(%User{theme: StyleHelpers.default()})

  defp index_board_bubble_theme(%User{theme: "elixir"}), do: "bg-gray-200"
  defp index_board_bubble_theme(%User{theme: "dark"}), do: "bg-gray-400"

  def board_dividers(nil), do: board_dividers(%User{theme: StyleHelpers.default()})
  def board_dividers(%User{theme: "elixir"}), do: "md:divide-y-2"
  def board_dividers(%User{theme: "dark"}), do: "md:divide-y-2 md:divide-gray-500"
end
