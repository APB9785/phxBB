defmodule PhxBbWeb.NewMessage do
  @moduledoc """
  New topic form.
  """
  use PhxBbWeb, :live_component

  alias PhxBb.Accounts
  alias PhxBb.Messages
  alias PhxBb.Messages.Message
  alias PhxBbWeb.StyleHelpers

  def mount(socket) do
    {:ok, assign(socket, message_sent: false, changeset: Messages.change_message(%Message{}))}
  end

  def update(%{active_user: active_user}, socket) do
    user_select =
      active_user.id
      |> Accounts.list_other_users()
      |> Enum.map(&{&1.name, &1.id})

    {:ok, assign(socket, active_user: active_user, user_select: user_select)}
  end

  def handle_event("new_message", %{"message" => params}, socket) do
    author_id = socket.assigns.active_user.id

    case Messages.create_message(params, author_id) do
      {:ok, _message} ->
        Phoenix.PubSub.broadcast(
          PhxBb.PubSub,
          "user:#{params["recipient_id"]}",
          {:unread_messages, &(&1 + 1)}
        )

        {:noreply,
         socket
         |> assign(changeset: Messages.change_message(%Message{}))
         |> assign(message_sent: true)}

      _ ->
        # Show validation error(s) only after failed submission
        changeset = Map.put(socket.assigns.changeset, :action, :insert)
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"message" => params}, socket) do
    changeset = Messages.change_message(%Message{}, params)
    # No live validation but still save the changeset
    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("clear_flash", _, socket) do
    {:noreply, assign(socket, message_sent: false)}
  end
end
