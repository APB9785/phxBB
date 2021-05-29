defmodule PhxBbWeb.PostContentComponent do
  @moduledoc """
  The content box for a post
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers,
    only: [format_time: 2, id_maker: 4, author?: 2, disabled?: 1, admin?: 1]

  import PhxBbWeb.StyleHelpers,
    only: [
      post_timestamp_style: 1,
      reply_form_style: 1,
      small_button_style: 1,
      post_edit_link_style: 1
    ]

  alias PhxBb.{Posts, Replies}

  def mount(socket) do
    {:ok, assign(socket, edit: false, delete: false)}
  end

  def update(assigns, socket) do
    changeset =
      case assigns.type do
        "reply" -> Replies.change_reply(assigns.post)
        "post" -> Posts.change_post(assigns.post)
      end

    {:ok, socket |> assign(assigns) |> assign(changeset: changeset)}
  end

  def handle_event("edit_post", _params, socket) do
    {:noreply, assign(socket, edit: true)}
  end

  def handle_event("save_edit", %{"post" => params}, socket) do
    params = %{edited_by: socket.assigns.active_user.id, body: params["body"]}

    case Posts.update_post(socket.assigns.post, params) do
      {:ok, post} ->
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "posts", {:edited_post, post})
        {:noreply, assign(socket, edit: false)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("save_edit", %{"reply" => params}, socket) do
    params = %{edited_by: socket.assigns.active_user.id, body: params["body"]}

    case Replies.update_reply(socket.assigns.post, params) do
      {:ok, reply} ->
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", {:edited_reply, reply})
        {:noreply, assign(socket, edit: false)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"reply" => params}, socket) do
    changeset =
      socket.assigns.post
      |> Replies.change_reply(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("validate", %{"post" => params}, socket) do
    changeset =
      socket.assigns.post
      |> Posts.change_post(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("cancel_edit", _params, socket) do
    changeset =
      case socket.assigns.type do
        "post" -> Posts.change_post(socket.assigns.post)
        "reply" -> Replies.change_reply(socket.assigns.post)
      end

    {:noreply, assign(socket, edit: false, changeset: changeset)}
  end

  def handle_event("delete_post", %{"id" => _post_id}, socket) do
    params = %{body: "_Post deleted._", edited_by: socket.assigns.active_user.id}
    {:ok, post} = Posts.update_post(socket.assigns.post, params)

    Phoenix.PubSub.broadcast(PhxBb.PubSub, "posts", {:edited_post, post})

    {:noreply, assign(socket, delete: false)}
  end

  def handle_event("delete_reply", _params, socket) do
    send(self(), {:backend_delete_reply, socket.assigns.post})
    {:noreply, socket}
  end

  def handle_event("delete_prompt", _params, socket) do
    {:noreply, assign(socket, delete: true)}
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
