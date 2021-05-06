defmodule PhxBbWeb.PostComponent do
  @moduledoc """
  View a post and its replies.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.StyleHelpers

  alias PhxBbWeb.PostAuthorComponent
  alias PhxBbWeb.PostContentComponent

  def render(assigns) do
    ~L"""
    <div class="block rounded-xl bg-gray-100 mb-4 md:flex md:rounded-none md:bg-transparent">
      <%= live_component @socket, PostAuthorComponent,
            active_user: @active_user,
            post: @active_post,
            user_cache: @user_cache %>

      <%= live_component @socket, PostContentComponent,
            active_user: @active_user,
            post: @active_post,
            id: "post-content-component" %>
    </div>

    <div class="<%= post_dividers(@active_user) %>">
      <%= for reply <- @reply_list do %>

        <div class="block rounded-xl bg-gray-100 mb-4 md:flex md:rounded-none md:bg-transparent">
          <%= live_component @socket, PostAuthorComponent,
                active_user: @active_user,
                post: reply,
                user_cache: @user_cache %>

          <%= live_component @socket, PostContentComponent,
                active_user: @active_user,
                post: reply,
                id: "reply-content-comp-" <> Integer.to_string(reply.id) %>
        </div>

      <% end %>
    </div>
    """
  end
end
