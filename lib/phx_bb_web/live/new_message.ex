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

  def update(%{current_user: current_user}, socket) do
    user_select =
      current_user.id
      |> Accounts.list_other_users()
      |> Enum.map(&{&1.name, &1.id})

    {:ok, assign(socket, current_user: current_user, user_select: user_select)}
  end

  def handle_event("new_message", %{"message" => params}, socket) do
    author_id = socket.assigns.current_user.id

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

  def render(assigns) do
    ~H"""
    <div>
      <div class="px-8">
        <%= if @message_sent do %>
          <p
            class="alert alert-info"
            id="message-sent-ok"
            phx-click="clear_flash"
            phx-target={@myself}
          >
            Message sent successfully.
          </p>
        <% end %>
      </div>
      <div class="flex w-full md:ml-8">
        <.form
          :let={f}
          for={to_form(@changeset)}
          id="new-message-form"
          class="grid w-full"
          phx-target={@myself}
          phx-submit="new_message"
          phx-change="validate"
        >
          <div class="flex">
            <div class="pr-4">
              Send to:
            </div>
            <div>
              <.input
                type="select"
                field={f[:recipient_id]}
                options={@user_select}
                class="rounded-sm border-black border"
              />
            </div>
          </div>
          <div class="h-4" />

          <div class="w-5/6">
            <.input
              type="text"
              field={f[:subject]}
              placeholder="Subject"
              phx-debounce="blur"
              autocomplete="off"
              class={StyleHelpers.user_form(@current_user)}
            />
          </div>
          <%!-- <div class="pl-6">
            {error_tag(f, :subject)}
          </div> --%>

          <div class="w-5/6 pt-2">
            <.input
              type="textarea"
              field={f[:body]}
              placeholder="Type your message here"
              phx-debounce="blur"
              autocomplete="off"
              class={StyleHelpers.user_form(@current_user)}
            />
          </div>
          <%!-- <div class="pl-6">
            {error_tag(f, :body)}
          </div> --%>

          <div class="h-4" />

          <%= if @current_user.disabled_at do %>
            <p>Your messaging privileges have been revoked by the forum administrator.</p>
          <% else %>
            <.button
              type="submit"
              phx-disable-with="Posting..."
              class={["px-2 rounded-md", StyleHelpers.button_theme(@current_user)]}
            >
              Send Message
            </.button>
          <% end %>
        </.form>
      </div>
    </div>
    """
  end
end
