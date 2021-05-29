defmodule PhxBbWeb.NewReplyComponent do
  @moduledoc """
  New Reply Form
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers, only: [replymaker: 3]
  import PhxBbWeb.StyleHelpers, only: [reply_form_style: 1, reply_button_style: 1]

  alias PhxBb.{Accounts, Boards, Posts, Replies}
  alias PhxBb.Replies.Reply

  def mount(socket) do
    {:ok, assign(socket, changeset: Replies.change_reply(%Reply{}))}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("new_reply", %{"reply" => params}, socket) do
    user = socket.assigns.active_user
    post = socket.assigns.active_post

    case replymaker(params["body"], post.id, user) do
      {:ok, reply} ->
        # Update the last reply info for the active post
        {1, _} = Posts.added_reply(post.id, user.id)
        # Update the last post info for the active board
        {1, _} = Boards.added_reply(post.board_id, post.id, user.id)
        # Update the user's post count
        {1, _} = Accounts.added_post(user.id)

        message = {:new_reply, reply, post.board_id}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

        {:noreply, assign(socket, changeset: Replies.change_reply(%Reply{}))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:disabled} ->
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"reply" => params}, socket) do
    changeset = Replies.change_reply(%Reply{}, params)
    # No live validation but still save the changeset
    {:noreply, assign(socket, changeset: changeset)}
  end
end
