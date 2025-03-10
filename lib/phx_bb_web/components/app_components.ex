defmodule PhxBbWeb.AppComponents do

  attr :id, :string
  attr :current_user, :map
  attr :post, :map

  def author_infobox(assigns) do
    ~H"""
    <div class={post_author_style(@current_user)} id={@id}>
  <div>
    <.link patch={~p"/forum/user/#{@post.author.id}"}
      class={StyleHelpers.link_style(@current_user)}
      phx_hook="ScrollToTop"
      id={"post-#{id}-author-profile-link"}
    >{@post.author.username}</.link>

    <div id={"post-#{@post.id}-author-title"} class="text-sm">
      {@post.author.title}
    </div>
  </div>

  <img
  :if={@post.author.avatar}
  src={@post.author.avatar}
      class={[
        "max-h-40 object-fill mr-4 h-10 w-10 border border-gray-700 rounded-xl",
        "md:h-auto md:w-32 md:mx-auto md:pt-2 md:border-none md:rounded-none"
      ]}
      id={"post-#{@post.id}-author-avatar"}
    />

<!-- This block hidden on devices with small screens -->
  <div class="hidden md:block">
    <p id={"post-#{@post.id}-author-post-count"} class="text-sm mt-4">
      Posts: {@post.author.post_count}
    </p>

    <p id={"post-#{@post.id}-author-join-date"} class="text-sm">
      Joined: {Timestamps.format_date(@post.author.inserted_at, @current_user)}
    </p>
  </div>
</div>
    """
  end

  defp post_author_style(user) do
    [
      "flex justify-end items-center flex-row-reverse pl-4 pb-2 pt-2 ",
      "md:pl-0 md:w-2/12 md:pt-4 md:text-center md:border-none md:block ",
      author_dividers(user)
    ]
  end

  defp author_dividers(nil), do: author_dividers(%User{theme: StyleHelpers.default()})
  defp author_dividers(%User{theme: "elixir"}), do: "border-b"
  defp author_dividers(%User{theme: "dark"}), do: "border-b border-gray-500"

  attr :current_user, :map
  attr :unread_messages, :list

  def user_menu(assigns) do
    ~H"""
    <%= case @current_user do %>
  <% nil -> %>
    <div class={user_menu(nil)} id="logged-out-menu">
      <div class="flex justify-center">
        <div>
          <.link patch={~p"/register"} id="user-menu-register" class={StyleHelpers.link_style(nil)}>Register</.link>
        </div>
        &nbsp;&nbsp;&nbsp;&nbsp;
        <div>
          <.link patch={~p"/login"} id="user-menu-login" class={StyleHelpers.link_style(nil)}>Log in</.link>
        </div>
      </div>
    </div>
  <% user -> %>
    <div class={user_menu(user)} id="logged-in-menu">
      <div class="text-center">
        Logged in as <.link patch={~p"/users/#{user.id}"} id="user-menu-profile" class={StyleHelpers.link_style(user)}>{user.username}</.link>
        <br />
      </div>
      <div class="flex justify-center flex-wrap">
        <%= if user.admin do %>
          <div>
            <.link patch={~p"/admin"} id="user-menu-admin" class={StyleHelpers.link_style(user)}>Admin Panel</.link>
          </div>
          &nbsp;&nbsp;&nbsp;&nbsp;
        <% end %>
        <div>
          <.link patch={~p"/settings"} id="user-menu-settings" class={StyleHelpers.link_style(user)}>Settings</.link>
        </div>
        &nbsp;&nbsp;&nbsp;&nbsp;
        <div>
          <.link patch={~p"/logout"} id="user-menu-logout" class={StyleHelpers.link_style(user)}>Log out</.link>
        </div>
      </div>
      <div class="flex justify-center">
        <div>
          <.link patch={~p"/messages"} id="user-menu-messages" class={StyleHelpers.link_style(user)}>Messages</.link>
        </div>
        <%= if @unread_messages > 0 do %>
          <div id="unread-message-notification">
            &nbsp;({@unread_messages})
          </div>
        <% end %>
      </div>
    </div>
<% end %>
    """
  end

  defp user_menu(user) do
    [
      "py-2 max-w-sm mx-auto rounded-lg md:rounded-md shadow-md antialiased ",
      "relative opacity-100 font-sans ",
      StyleHelpers.content_bg_theme(user)
    ]
  end
end
