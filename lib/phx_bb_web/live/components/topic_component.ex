defmodule PhxBbWeb.TopicComponent do
  @moduledoc """
  View a post and its replies.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBbWeb.PostAuthorComponent
  alias PhxBbWeb.PostContentComponent

  def render(assigns) do
    ~L"""
    <div class="block rounded-xl bg-gray-100 mb-4 md:flex md:rounded-none md:bg-transparent">
      <%= live_component @socket, PostAuthorComponent,
            active_user: @active_user,
            post: @active_post,
            type: "post",
            user_cache: @user_cache %>

      <%= live_component @socket, PostContentComponent,
            active_user: @active_user,
            post: @active_post,
            type: "post",
            user_cache: @user_cache,
            id: "post-content-component" %>
    </div>

    <div class="<%= post_dividers(@active_user) %>">
      <%= for reply <- @reply_list do %>

        <div class="block rounded-xl bg-gray-100 mb-4 md:flex md:rounded-none md:bg-transparent">
          <%= live_component @socket, PostAuthorComponent,
                active_user: @active_user,
                post: reply,
                type: "reply",
                user_cache: @user_cache %>

          <%= live_component @socket, PostContentComponent,
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
