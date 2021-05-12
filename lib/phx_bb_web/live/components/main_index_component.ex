defmodule PhxBbWeb.MainIndexComponent do
  @moduledoc """
  Main Index.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    users =
      Enum.reduce(socket.assigns.board_list, [], fn board, acc ->
        case board.last_user do
          nil -> acc
          last_user -> [last_user | acc]
        end
      end)

    cache = Accounts.build_cache(users, socket.assigns.user_cache)
    socket = assign(socket, user_cache: cache)
    {:ok, socket}
  end
end
