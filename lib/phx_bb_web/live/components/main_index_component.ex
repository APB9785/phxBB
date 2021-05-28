defmodule PhxBbWeb.MainIndexComponent do
  @moduledoc """
  Main Index.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBbWeb.UserCache

  def update(assigns, socket) do
    cache = UserCache.from_board_list(assigns.board_list, assigns.user_cache)

    {:ok, socket |> assign(assigns) |> assign(user_cache: cache)}
  end
end
