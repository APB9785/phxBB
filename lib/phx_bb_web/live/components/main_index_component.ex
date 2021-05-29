defmodule PhxBbWeb.MainIndexComponent do
  @moduledoc """
  Main Index.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers, only: [shortener: 1, format_time: 2]

  import PhxBbWeb.StyleHelpers,
    only: [
      link_style: 1,
      board_stats_style: 1,
      board_title_style: 1,
      index_board_bubble_style: 1,
      board_dividers: 1
    ]

  alias PhxBb.Boards.Board

  def update(assigns, socket) do
    cache = PhxBbWeb.UserCache.from_board_list(assigns.board_list, assigns.user_cache)

    {:ok, socket |> assign(assigns) |> assign(user_cache: cache)}
  end

  def display_title(post_id) do
    post_id
    |> PhxBb.Posts.get_title()
    |> shortener
  end

  def topic_count_display(%Board{topic_count: 1}), do: "1 topic"
  def topic_count_display(%Board{topic_count: count}), do: "#{count} topics"

  def post_count_display(%Board{post_count: 1}), do: "1 post"
  def post_count_display(%Board{post_count: count}), do: "#{count} posts"
end
