defmodule PhxBbWeb.MainIndex do
  @moduledoc """
  Main Index.
  """
  use PhxBbWeb, :live_view

  alias PhxBbWeb.Parsers
  alias PhxBbWeb.StyleHelpers

  def mount(socket) do
    {:ok, assign(socket, board_list: PhxBb.Boards.list_boards())}
  end

  def topic_count_display(%{topic_count: 1}), do: "1 topic"
  def topic_count_display(%{topic_count: count}), do: "#{count} topics"

  def post_count_display(%{post_count: 1}), do: "1 post"
  def post_count_display(%{post_count: count}), do: "#{count} posts"

  def render(assigns) do
    ~H"""
    <div class={board_dividers(@current_user)}>
      <div :for={board <- @board_list} class={index_board_bubble_style(@current_user)}>
        <div class="py-4 px-4 md:px-8 md:w-7/12">
          <.link
            patch={~p"/board/#{board.id}"}
            class={["hover:underline font-bold text-lg", StyleHelpers.text_theme(@current_user)]}
            id={"board-#{board.id}-link"}
          >
            {board.name}
          </.link>
          <div id={"board-#{board.id}-description"} class="text-sm">
            {board.description}
          </div>
        </div>

        <div class={board_stats_style(@current_user)}>
          <div id={"board-#{board.id}-topic-count"} class="text-sm text-center">
            {topic_count_display(board)}
          </div>
          <div id={"board-#{board.id}-post-count"} class="text-sm ml-2 md:ml-0 md:mt-2 text-center">
            {post_count_display(board)}
          </div>
        </div>

        <%= if !is_nil(board.recent_topic_id) do %>
          <div class="flex items-center pl-4 pb-2 md:p-4 text-sm md:w-1/3">
            <div>
              <div>
                Last post by
                <.link
                  patch={~p"/user/#{board.recent_user.id}"}
                  class={StyleHelpers.link_style(@current_user)}
                  id={"board-#{board.id}-recent-author-link"}
                >
                  {board.recent_user.username}
                </.link>
              </div>
              <div>
                in
                <.link
                  patch={~p"/topic/#{board.recent_topic.id}"}
                  class={StyleHelpers.text_theme(@current_user)}
                  id={"board-#{board.id}-recent-topic-link"}
                >
                  {Parsers.shortener(board.recent_topic.title)}
                </.link>
              </div>
              <div class="hidden md:block">
                {PhxBbWeb.Timestamps.format_time(board.updated_at, @current_user)}
              </div>
            </div>
          </div>
        <% else %>
          <div
            id={"board-#{board.id}-no-topics-yet"}
            class="pb-4 pl-4 flex items-center md:p-4 text-sm md:text-base md:w-1/3"
          >
            <div>No topics yet!</div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  ## Tailwind styles

  def board_stats_style(user), do: [board_stats_base(), " ", board_stats_theme(user)]

  defp board_stats_base do
    "pl-4 pt-2 text-sm border-t flex md:p-4 md:text-base md:grid md:border-0 md:w-1/12 md:content-evenly"
  end

  defp board_stats_theme(nil), do: board_stats_theme(%{theme: StyleHelpers.default()})
  defp board_stats_theme(%{theme: "elixir"}), do: "border-gray-300"
  defp board_stats_theme(%{theme: "dark"}), do: "border-gray-500"

  def index_board_bubble_style(user) do
    [
      "rounded-lg m-1 md:bg-transparent md:rounded-t-none md:flex md:m-0",
      index_board_bubble_theme(user)
    ]
  end

  defp index_board_bubble_theme(nil),
    do: index_board_bubble_theme(%{theme: StyleHelpers.default()})

  defp index_board_bubble_theme(%{theme: "elixir"}), do: "bg-gray-200"
  defp index_board_bubble_theme(%{theme: "dark"}), do: "bg-gray-400"

  def board_dividers(nil), do: board_dividers(%{theme: StyleHelpers.default()})
  def board_dividers(%{theme: "elixir"}), do: "md:divide-y-2"
  def board_dividers(%{theme: "dark"}), do: "md:divide-y-2 md:divide-gray-500"
end
