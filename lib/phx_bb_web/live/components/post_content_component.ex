defmodule PhxBbWeb.PostContentComponent do
  @moduledoc """
  The content box for a post
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Posts
  alias PhxBb.Replies

  def mount(socket) do
    socket = assign(socket, edit: false, delete: false)
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    post = socket.assigns.post
    socket =
      if post_is_reply?(post) do
        assign(socket, changeset: Replies.change_reply(post))
      else
        assign(socket, changeset: Posts.change_post(post))
      end
    {:ok, socket}
  end

  def handle_event("edit_post", _params, socket) do
    # Should send PubSub to warn readers!
    socket = assign(socket, edit: true)
    {:noreply, socket}
  end

  def handle_event("save_edit", %{"post" => params}, socket) do
    case Posts.update_post(socket.assigns.post, params) do
      {:ok, post} ->
        # Update locally
        socket = assign(socket, post: post, edit: false)
        # Send PubSub message to update

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("save_edit", %{"reply" => params}, socket) do
    case Replies.update_reply(socket.assigns.post, params) do
      {:ok, reply} ->
        # Update locally
        socket = assign(socket, post: reply, edit: false)
        # Send PubSub message to update

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"reply" => params}, socket) do
    changeset =
      socket.assigns.post
      |> Replies.change_reply(params)
      |> Map.put(:action, :insert)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("validate", %{"post" => params}, socket) do
    changeset =
      socket.assigns.post
      |> Posts.change_post(params)
      |> Map.put(:action, :insert)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("cancel_edit", _params, socket) do
    socket =
      assign(socket,
        edit: false,
        changeset: Ecto.Changeset.delete_change(socket.assigns.changeset, :body))

    {:noreply, socket}
  end

  def handle_event("delete_post", %{"id" => post_id}, socket) do
    # DB update
    Posts.delete_post_body(post_id, socket.assigns.active_user.id)
    # Local update
    socket = assign(socket, post: %{socket.assigns.post | body: "_Post deleted._"}, delete: false)
    # Need to add PubSub message
    {:noreply, socket}
  end

  def handle_event("delete_reply", %{"id" => id}, socket) do
    # DB update
    Replies.delete_reply(socket.assigns.post)
    # Local update
    send(self(), {:delete_reply, String.to_integer(id)})
    # Need to add PubSub message
    {:noreply, socket}
  end

  def handle_event("delete_prompt", _params, socket) do
    socket = assign(socket, delete: true)
    {:noreply, socket}
  end

  # Helpers

  def edit_post_form_value(changeset) do
    case changeset.changes[:body] do
      nil -> changeset.data.body
      changed_body -> changed_body
    end
  end

  def delete_click_event(post) do
    if post_is_reply?(post) do
      "delete_reply"
    else
      "delete_post"
    end
  end
end
