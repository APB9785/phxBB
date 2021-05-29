defmodule PhxBbWeb.UsersOnlineComponent do
  @moduledoc """
  Shows a list of online users via Phoenix Presence.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.StyleHelpers

  def guest?(id) when is_binary(id), do: String.at(id, 0) == "-"
end
