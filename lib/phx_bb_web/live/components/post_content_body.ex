defmodule PhxBbWeb.PostContentBody do
  @moduledoc """
  Shows the post or reply body when not being edited.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.Parsers, only: [parse_post_body: 1]

  alias PhxBbWeb.Timestamps

  def render(assigns) do
    ~H"""
    <div id={"post-#{@active_post.id}-body"}>
      <%= parse_post_body(@active_post.body) %>

      <%= if @active_post.edited_by do %>
        <br>
        <div class="italic text-sm">
          Edited by <%= @active_post.edited_by.username %> on <%= Timestamps.format_time(@active_post.updated_at, @active_user) %>
        </div>
      <% end %>
    </div>
    """
  end
end
