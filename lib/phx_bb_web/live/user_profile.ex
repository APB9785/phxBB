defmodule PhxBbWeb.UserProfile do
  @moduledoc """
  Viewing a user's profile.
  """
  use PhxBbWeb, :live_view

  alias PhxBb.Accounts
  alias PhxBbWeb.Parsers
  alias PhxBbWeb.StyleHelpers
  alias PhxBbWeb.Timestamps

  def mount(params, _session, socket) do
    view_user = Accounts.get_user(params["user_id"])

    socket =
      assign(socket,
        post_history: Accounts.last_five_posts(view_user.id),
        view_user: view_user
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="text-2xl pb-0 md:pl-8 md:pt-4 font-bold" id="user-profile-header">
        {@view_user.username}
      </div>

      <div class="pb-4 md:pl-8" id="user-profile-title">
        {@view_user.title}
      </div>

      <div class="pb-4 md:pl-8" id="user-profile-title">
        Joined {Timestamps.format_date(@view_user.inserted_at, @current_user)}
      </div>

      <div class="w-32 md:ml-8">
        <img src={@view_user.avatar} class="max-h-40 w-full object-fill pb-4" />
      </div>

      <div class="text-2xl md:pl-8 md:pb-2">
        Latest 5 posts:
      </div>

      <%= for post <- @post_history do %>
        <div class="text-sm md:pl-10 pt-2">
          in <.link
            patch={~p"/topic/#{post.topic.id}"}
            class={StyleHelpers.link_style(@current_user)}
            id={"post-#{post.id}-link"}
          >{Parsers.shortener(post.topic.title)}</.link>:
        </div>
        <div class={user_history_bubble_style(@current_user)}>
          <div class={user_history_timestamp_style(@current_user)}>
            {Timestamps.format_time(post.inserted_at, @current_user)}
          </div>
          <p class="pl-2 w-max">
            {Parsers.parse_post_body(post.body)}
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  ## Tailwind Styles

  def user_history_bubble_style(user) do
    [
      "p-2 pb-4 pr-4 rounded-xl w-max max-w-full md:max-w-prose shadow-md md:mx-8 ",
      StyleHelpers.content_bubble_theme(user)
    ]
  end

  def user_history_timestamp_style(user),
    do: ["text-sm w-40 pb-2 ", StyleHelpers.timestamp_theme(user)]
end
