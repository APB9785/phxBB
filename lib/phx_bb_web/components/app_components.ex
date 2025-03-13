defmodule PhxBbWeb.AppComponents do
  use Phoenix.Component
  use Gettext, backend: PhxBbWeb.Gettext
  use PhxBbWeb, :verified_routes

  alias Phoenix.LiveView.JS
  alias PhxBbWeb.StyleHelpers

  attr :id, :string
  attr :current_user, :map
  attr :post, :map

  def author_infobox(assigns) do
    ~H"""
    <div class={post_author_style(@current_user)} id={@id}>
      <div>
        <.link
          patch={~p"/forum/user/#{@post.author.id}"}
          class={StyleHelpers.link_style(@current_user)}
          phx_hook="ScrollToTop"
          id={"post-#{@post.id}-author-profile-link"}
        >
          {@post.author.username}
        </.link>

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

  defp author_dividers(nil), do: author_dividers(%{theme: StyleHelpers.default()})
  defp author_dividers(%{theme: "elixir"}), do: "border-b"
  defp author_dividers(%{theme: "dark"}), do: "border-b border-gray-500"

  attr :current_user, :map
  attr :unread_messages, :list

  def user_menu(assigns) do
    ~H"""
    <%= case @current_user do %>
      <% nil -> %>
        <div class={user_menu_class(nil)} id="logged-out-menu">
          <div class="flex justify-center">
            <div>
              <.link
                patch={~p"/register"}
                id="user-menu-register"
                class={StyleHelpers.link_style(nil)}
              >
                Register
              </.link>
            </div>
            &nbsp;&nbsp;&nbsp;&nbsp;
            <div>
              <.link patch={~p"/login"} id="user-menu-login" class={StyleHelpers.link_style(nil)}>
                Log in
              </.link>
            </div>
          </div>
        </div>
      <% user -> %>
        <div class={user_menu_class(user)} id="logged-in-menu">
          <div class="text-center">
            Logged in as
            <.link
              patch={~p"/users/#{user.id}"}
              id="user-menu-profile"
              class={StyleHelpers.link_style(user)}
            >
              {user.username}
            </.link>
            <br />
          </div>
          <div class="flex justify-center flex-wrap">
            <%= if user.admin do %>
              <div>
                <.link patch={~p"/admin"} id="user-menu-admin" class={StyleHelpers.link_style(user)}>
                  Admin Panel
                </.link>
              </div>
              &nbsp;&nbsp;&nbsp;&nbsp;
            <% end %>
            <div>
              <.link
                patch={~p"/settings"}
                id="user-menu-settings"
                class={StyleHelpers.link_style(user)}
              >
                Settings
              </.link>
            </div>
            &nbsp;&nbsp;&nbsp;&nbsp;
            <div>
              <.link patch={~p"/logout"} id="user-menu-logout" class={StyleHelpers.link_style(user)}>
                Log out
              </.link>
            </div>
          </div>
          <div class="flex justify-center">
            <div>
              <.link
                patch={~p"/messages"}
                id="user-menu-messages"
                class={StyleHelpers.link_style(user)}
              >
                Messages
              </.link>
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

  defp user_menu_class(user) do
    [
      "py-2 max-w-sm mx-auto rounded-lg md:rounded-md shadow-md antialiased ",
      "relative opacity-100 font-sans ",
      StyleHelpers.content_bg_theme(user)
    ]
  end

  attr :users_online, :list
  attr :current_user, :map

  def users_online(assigns) do
    ~H"""
    <div class={users_online_style(@current_user)}>
      <h2 class="pr-2 text-lg text-gray-200">
        Users online:
      </h2>
      <%= for {user_id, user} <- @users_online do %>
        <div class={online_user_bubble_style(@current_user)}>
          <%= if guest?(user_id) do %>
            <div id={"online-guest#{user_id}"} class="italic">
              {user.name}
            </div>
          <% else %>
            <div>
              <.link
                patch={~p"/user/#{user_id}"}
                class={StyleHelpers.link_style(@current_user)}
                id={"online-user-#{user_id}"}
              >
                {user.name}
              </.link>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp guest?(id) when is_binary(id), do: String.at(id, 0) == "-"

  defp users_online_style(user), do: [users_online_base(), " ", users_online_theme(user)]

  defp users_online_base do
    "shadow-inner px-4 md:px-8 flex flex-wrap mx-1 md:mx-4 rounded-lg md:rounded-md py-4"
  end

  defp users_online_theme(nil), do: users_online_theme(%{theme: StyleHelpers.default()})
  defp users_online_theme(%{theme: "elixir"}), do: "bg-purple-700"
  defp users_online_theme(%{theme: "dark"}), do: "bg-gray-800"

  def online_user_bubble_style(user) do
    [online_user_bubble_base(), " ", online_user_bubble_theme(user)]
  end

  defp online_user_bubble_base do
    "px-1 mx-1 rounded-lg text-sm flex items-center shadow-inner"
  end

  defp online_user_bubble_theme(nil),
    do: online_user_bubble_theme(%{theme: StyleHelpers.default()})

  defp online_user_bubble_theme(%{theme: "elixir"}), do: "bg-gray-200"
  defp online_user_bubble_theme(%{theme: "dark"}), do: "bg-gray-300"

  attr :active_post, :map
  attr :current_user, :map

  def post_content_body(assigns) do
    ~H"""
    <div id={"post-#{@active_post.id}-body"}>
      {Parsers.parse_post_body(@active_post.body)}

      <%= if @active_post.edited_by do %>
        <br />
        <div class="italic text-sm">
          Edited by {@active_post.edited_by.username} on {Timestamps.format_time(
            @active_post.updated_at,
            @current_user
          )}
        </div>
      <% end %>
    </div>
    """
  end
end
