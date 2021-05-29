defmodule PhxBbWeb.BoardComponent do
  @moduledoc """
  Board view.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers, only: [format_time: 2]

  import PhxBbWeb.StyleHelpers,
    only: [new_post_button_style: 1, post_dividers: 1, topic_bubble_style: 1, link_style: 1]

  alias PhxBb.Posts.Post

  def view_count_display(%Post{view_count: 1}), do: "1 view"
  def view_count_display(%Post{view_count: count}), do: "#{count} views"

  def reply_count_display(%Post{reply_count: 1}), do: "1 reply"
  def reply_count_display(%Post{reply_count: count}), do: "#{count} replies"
end
