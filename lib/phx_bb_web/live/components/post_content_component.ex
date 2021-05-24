defmodule PhxBbWeb.PostContentComponent do
  @moduledoc """
  The content box for a post
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Posts
  alias PhxBb.Replies
  alias PhxBbWeb.PostContentBodyComponent

  def mount(socket) do
    socket = assign(socket, edit: false, delete: false)
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    post = socket.assigns.post

    socket =
      case socket.assigns.type do
        "reply" -> assign(socket, changeset: Replies.change_reply(post))
        "post" -> assign(socket, changeset: Posts.change_post(post))
      end

    {:ok, socket}
  end

  def handle_event("edit_post", _params, socket) do
    socket = assign(socket, edit: true)
    {:noreply, socket}
  end

  def handle_event("save_edit", %{"post" => params}, socket) do
    params = %{edited_by: socket.assigns.active_user.id, body: params["body"]}

    case Posts.update_post(socket.assigns.post, params) do
      {:ok, post} ->
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "posts", {:edited_post, post})
        socket = assign(socket, edit: false)
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("save_edit", %{"reply" => params}, socket) do
    params = %{edited_by: socket.assigns.active_user.id, body: params["body"]}

    case Replies.update_reply(socket.assigns.post, params) do
      {:ok, reply} ->
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", {:edited_reply, reply})
        socket = assign(socket, edit: false)
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
    changeset =
      case socket.assigns.type do
        "post" -> Posts.change_post(socket.assigns.post)
        "reply" -> Replies.change_reply(socket.assigns.post)
      end

    socket = assign(socket, edit: false, changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("delete_post", %{"id" => _post_id}, socket) do
    params = %{body: "_Post deleted._", edited_by: socket.assigns.active_user.id}
    {:ok, post} = Posts.update_post(socket.assigns.post, params)

    Phoenix.PubSub.broadcast(PhxBb.PubSub, "posts", {:edited_post, post})

    socket = assign(socket, delete: false)
    {:noreply, socket}
  end

  def handle_event("delete_reply", _params, socket) do
    send(self(), {:backend_delete_reply, socket.assigns.post})
    {:noreply, socket}
  end

  def handle_event("delete_prompt", _params, socket) do
    socket = assign(socket, delete: true)
    {:noreply, socket}
  end

  # Helpers

  def edit_post_form_value(changeset) do
    case changeset.changes[:body] do
      nil -> if changeset.errors == [], do: changeset.data.body, else: ""
      changed_body -> changed_body
    end
  end

  def may_edit?(user, post) do
    cond do
      admin?(user) -> true
      author?(user, post) and !disabled?(user) -> true
      true -> false
    end
  end
end
