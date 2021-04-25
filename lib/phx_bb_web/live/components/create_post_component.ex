defmodule PhxBbWeb.CreatePostComponent do
  @moduledoc """
  New post form.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Posts
  alias PhxBb.Posts.Post

  def mount(socket) do
    socket = assign(socket, changeset: Posts.change_post(%Post{}))
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def handle_event("new_post", %{"post" => params}, socket) do
    user = socket.assigns.active_user
    board = socket.assigns.active_board

    case postmaker(params["body"], params["title"], board.id, user.id) do
      {:ok, post} ->
        # Update the last post info for the active board
        {1, _} = Boards.added_post(board.id, post.id, user.id)
        # Update the user's post count
        {1, _} = Accounts.added_post(user.id)

        socket =
          push_patch(socket,
            to: Routes.live_path(socket, PhxBbWeb.PageLive, board: board.id))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end
end
