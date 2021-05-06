defmodule PhxBbWeb.PostAuthorComponent do
  @moduledoc """
  Author infobox for each post
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  def render(assigns) do
    ~L"""
    <div class="flex justify-end flex-row-reverse pl-4 border-b-2 pb-2 pt-2
               md:pl-0 md:w-2/12 md:pt-4 md:text-center md:border-none md:block"
         id="post-author-info">
      <div>
        <%= live_patch @user_cache[@post.author].name,
              to: Routes.live_path(@socket, PhxBbWeb.PageLive, user: @post.author),
              class: link_style(@active_user),
              phx_hook: "ScrollToTop" %>

        <div class="text-sm"><%= @user_cache[@post.author].title %></div>
      </div>

      <%= if @user_cache[@post.author].avatar do %>
        <%= img_tag @user_cache[@post.author].avatar,
                    class: "max-h-40 object-fill mr-4 h-10 w-10 md:h-auto md:w-32 md:mx-auto md:pt-2" %>
      <% end %>

      <!-- This block hidden on devices with small screens -->
      <div class="hidden md:block">
        <p class="text-sm mt-4" id="author-post-count">
          Posts: <%= @user_cache[@post.author].post_count %>
        </p>

        <p class="text-sm" id="author-join-date">
          Joined: <%= format_date(@user_cache[@post.author].joined, @active_user) %>
        </p>
      </div>
    </div>
    """
  end
end
