defmodule PhxBbWeb.Inbox do
  @moduledoc """
  Current user's message inbox.
  """
  use PhxBbWeb, :live_view

  alias PhxBb.Messages
  alias PhxBbWeb.StyleHelpers

  def mount(_params, _session, socket) do
    messages = Messages.for_user(socket.assigns.current_user.id)

    {:ok, assign(socket, message_list: messages)}
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

  def render(assigns) do
    ~H"""
    <div class="mx-8">
      <div class="pb-6">
        <.link
          patch={~p"/messages/new"}
          id="new-message-link"
          class={StyleHelpers.link_style(@current_user)}
        >
          New Message
        </.link>
      </div>

      <div class="divide-y divide-black divide-solid border border-black">
        <div :for={message <- @message_list} class="py-4 pl-2">
          <div class="flex justify-between">
            <div class="flex pr-24 pl-2">
              <div class="text-2xl font-bold self-end pr-6">
                {message.subject}
              </div>
              <div class="self-end">
                from
                <.link
                  patch={~p"/users/#{message.author.id}"}
                  id={"author-#{message.author.id}-link"}
                  class={StyleHelpers.link_style(@current_user)}
                >
                  {message.author.username}
                </.link>
              </div>
            </div>

            <%= if message.read_at do %>
              <div
                class="cursor-pointer self-end pr-4"
                id={"mark-unread-button-#{message.id}"}
                phx-click="mark_unread"
                phx-value-id={message.id}
              >
                Mark Unread
              </div>
            <% else %>
              <div
                class="cursor-pointer self-end pr-4"
                id={"mark-read-button-#{message.id}"}
                phx-click="mark_read"
                phx-value-id={message.id}
              >
                Mark as Read
              </div>
            <% end %>
          </div>

          <div class={["rounded-lg mr-2 ", StyleHelpers.content_bubble_theme(@current_user)]}>
            <div class="py-2 pl-4">
              {message.body}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
