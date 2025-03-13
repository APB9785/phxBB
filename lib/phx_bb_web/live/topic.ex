defmodule PhxBbWeb.Topic do
  @moduledoc """
  View a Topic and its posts.
  """
  use PhxBbWeb, :live_view

  alias PhxBbWeb.StyleHelpers

  def render(assigns) do
    ~H"""
    <div id="post-list" class={post_dividers(@current_user)} phx-update="append">
      <div :for={post <- @post_list} id={"post-#{post.id}"} class={topic_content_style(@current_user)}>
        <.author_infobox current_user={@current_user} post={post} id={"post-#{post.id}-author-info"} />

        <.live_component
          module={PhxBbWeb.PostContent}
          current_user={@current_user}
          active_post={post}
          id={"post-#{post.id}-content"}
        />
      </div>
    </div>
    """
  end

  def topic_content_style(user) do
    [
      "block rounded-xl mb-4 md:flex md:rounded-none md:bg-transparent ",
      StyleHelpers.content_bg_theme(user)
    ]
  end

  def post_dividers(nil), do: post_dividers(%{theme: StyleHelpers.default()})
  def post_dividers(%{theme: "elixir"}), do: "md:border-t-2 md:border-b-2 md:divide-y-2"

  def post_dividers(%{theme: "dark"}) do
    "md:border-t-2 md:border-b-2 md:divide-y-2 md:border-gray-500 md:divide-gray-500"
  end
end
