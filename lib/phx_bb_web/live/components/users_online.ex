defmodule PhxBbWeb.UsersOnline do
  @moduledoc """
  Shows a list of online users via Phoenix Presence.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBbWeb.StyleHelpers

  def guest?(id) when is_binary(id), do: String.at(id, 0) == "-"

  def link_to_user(username, user_id, active_user) do
    live_patch(username,
      to: Routes.live_path(PhxBbWeb.Endpoint, PhxBbWeb.ForumLive, user: user_id),
      class: PhxBbWeb.StyleHelpers.link_style(active_user),
      phx_hook: "ScrollToTop",
      id: "online-user-#{user_id}"
    )
  end

  ## Tailwind styles

  def users_online_style(user), do: [users_online_base(), " ", users_online_theme(user)]

  defp users_online_base do
    "shadow-inner px-4 md:px-8 flex flex-wrap mx-1 md:mx-4 rounded-lg md:rounded-md py-4"
  end

  defp users_online_theme(nil), do: users_online_theme(%User{theme: StyleHelpers.default()})
  defp users_online_theme(%User{theme: "elixir"}), do: "bg-purple-700"
  defp users_online_theme(%User{theme: "dark"}), do: "bg-gray-800"

  def online_user_bubble_style(user) do
    [online_user_bubble_base(), " ", online_user_bubble_theme(user)]
  end

  defp online_user_bubble_base do
    "px-1 mx-1 rounded-lg text-sm flex items-center shadow-inner"
  end

  defp online_user_bubble_theme(nil),
    do: online_user_bubble_theme(%User{theme: StyleHelpers.default()})

  defp online_user_bubble_theme(%User{theme: "elixir"}), do: "bg-gray-200"
  defp online_user_bubble_theme(%User{theme: "dark"}), do: "bg-gray-300"
end
