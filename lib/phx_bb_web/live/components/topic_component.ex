defmodule PhxBbWeb.TopicComponent do
  @moduledoc """
  View a post and its replies.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers, only: [id_maker: 4]
  import PhxBbWeb.StyleHelpers, only: [post_content_style: 1, post_dividers: 1]

  def render(assigns) do
    ~L"""
    <div class="<%= post_content_style(@active_user) %>">
      <%= live_component @socket, PhxBbWeb.PostAuthorComponent,
            active_user: @active_user,
            post: @active_post,
            type: "post",
            user_cache: @user_cache %>

      <%= live_component @socket, PhxBbWeb.PostContentComponent,
            active_user: @active_user,
            post: @active_post,
            type: "post",
            user_cache: @user_cache,
            id: "post-content-component" %>
    </div>

    <div class="<%= post_dividers(@active_user) %>">
      <%= for reply <- @reply_list do %>

        <div class="<%= post_content_style(@active_user) %>">
          <%= live_component @socket, PhxBbWeb.PostAuthorComponent,
                active_user: @active_user,
                post: reply,
                type: "reply",
                user_cache: @user_cache %>

          <%= live_component @socket, PhxBbWeb.PostContentComponent,
                active_user: @active_user,
                post: reply,
                type: "reply",
                user_cache: @user_cache,
                id: id_maker("reply", "content", "comp", reply.id) %>
        </div>

      <% end %>
    </div>
    """
  end
end
