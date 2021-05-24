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

    case postmaker(params["body"], params["title"], board.id, user) do
      {:ok, post} ->
        # Update the last post info for the active board
        {1, _} = Boards.added_post(board.id, post.id, user.id)
        # Update the user's post count
        {1, _} = Accounts.added_post(user.id)

        message = {:new_topic, user.id, post.id, post.board_id}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "posts", message)

        socket =
          push_patch(socket,
            to: Routes.live_path(socket, PhxBbWeb.PageLive, board: board.id)
          )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}

      {:disabled} ->
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"post" => params}, socket) do
    changeset =
      %Post{}
      |> Posts.change_post(params)
      |> Map.put(:action, :insert)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end
end
