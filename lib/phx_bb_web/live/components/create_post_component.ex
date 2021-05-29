defmodule PhxBbWeb.CreatePostComponent do
  @moduledoc """
  New post form.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers, only: [postmaker: 4]

  import PhxBbWeb.StyleHelpers,
    only: [topic_title_form_style: 1, topic_body_form_style: 1, button_style: 1]

  alias PhxBb.{Accounts, Boards, Posts}
  alias PhxBb.Posts.Post

  def mount(socket) do
    {:ok, assign(socket, changeset: Posts.change_post(%Post{}))}
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

        {:noreply,
         push_patch(socket, to: Routes.live_path(socket, PhxBbWeb.PageLive, board: board.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:disabled} ->
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"post" => params}, socket) do
    changeset =
      %Post{}
      |> Posts.change_post(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end
end
