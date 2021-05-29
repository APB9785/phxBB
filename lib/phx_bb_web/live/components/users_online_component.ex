defmodule PhxBbWeb.UsersOnlineComponent do
  @moduledoc """
  Shows a list of online users via Phoenix Presence.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.StyleHelpers,
    only: [users_online_style: 1, online_user_bubble_style: 1, link_style: 1]

  def guest?(id) when is_binary(id), do: String.at(id, 0) == "-"
end
