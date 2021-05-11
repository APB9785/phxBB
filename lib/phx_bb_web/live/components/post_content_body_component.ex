defmodule PhxBbWeb.PostContentBodyComponent do
  @moduledoc """
  Shows the post or reply body when not being edited.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers

  def render(assigns) do
    ~L"""
    <div>
      <%= parse_post_body(@post.body) %>

      <%= if @post.edited_by do %>
        <br>
        <div class="italic text-sm">
          Edited by <%= editor_name(@user_cache, @post) %> on <%= format_time(@post.updated_at, @active_user) %>
        </div>
      <% end %>
    </div>
    """
  end

  def editor_name(user_cache, post) do
    user_cache[post.edited_by].name
  end
end
