defmodule PhxBbWeb.NewReplyComponent do
  @moduledoc """
  New Reply Form
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Posts
  alias PhxBb.Replies
  alias PhxBb.Replies.Reply

  def mount(socket) do
    socket = assign(socket, changeset: Replies.change_reply(%Reply{}))
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def handle_event("new_reply", %{"reply" => params}, socket) do
    user = socket.assigns.active_user
    post = socket.assigns.active_post

    case replymaker(params["body"], post.id, user.id) do
      {:ok, reply} ->
        # Update the last reply info for the active post
        {1, _} = Posts.added_reply(post.id, user.id)
        # Update the last post info for the active board
        {1, _} = Boards.added_reply(post.board_id, post.id, user.id)
        # Update the user's post count
        {1, _} = Accounts.added_post(user.id)

        message = {:new_reply, post.id, reply}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

        socket = assign(socket, changeset: Replies.change_reply(%Reply{}))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"reply" => params}, socket) do
    changeset =
      %Reply{}
      |> Replies.change_reply(params)
      |> Map.put(:action, :insert)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end
end
