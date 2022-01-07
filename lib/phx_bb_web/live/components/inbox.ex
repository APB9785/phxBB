defmodule PhxBbWeb.Inbox do
  @moduledoc """
  Current user's message inbox.
  """
  use PhxBbWeb, :live_component

  alias PhxBb.Messages
  alias PhxBbWeb.Endpoint
  alias PhxBbWeb.ForumLive
  alias PhxBbWeb.StyleHelpers

  def update(%{active_user: active_user}, socket) do
    messages = Messages.for_user(active_user.id)

    {:ok, assign(socket, message_list: messages, active_user: active_user)}
  end

  def handle_event("mark_read", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:ok, message} = Messages.mark_read(id)

    send(self(), {:unread_messages, &(&1 - 1)})

    {:noreply, update_message_list(socket, message)}
  end

  def handle_event("mark_unread", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:ok, message} = Messages.mark_unread(id)

    send(self(), {:unread_messages, &(&1 + 1)})

    {:noreply, update_message_list(socket, message)}
  end

  defp update_message_list(socket, new_message) do
    update(
      socket,
      :message_list,
      &Enum.map(&1, fn message ->
        if message.id == new_message.id, do: new_message, else: message
      end)
    )
  end

  def new_message_link(user) do
    live_patch("New Message",
      to: Routes.live_path(Endpoint, ForumLive, messages: "new"),
      id: "new-message-link",
      class: StyleHelpers.link_style(user)
    )
  end

  def author_link(user, author) do
    live_patch(author.username,
      to: Routes.live_path(Endpoint, ForumLive, user: author.id),
      id: "author-#{author.id}-link",
      class: StyleHelpers.link_style(user)
    )
  end
end
