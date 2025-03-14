defmodule PhxBbWeb.AdminPanel do
  @moduledoc """
  Provides the Admin user(s) a UI for making changes to the forum.
  """
  use PhxBbWeb, :live_view

  alias PhxBb.Accounts
  alias PhxBbWeb.StyleHelpers

  def mount(socket) do
    auid = socket.assigns.current_user.id
    users = auid |> Accounts.list_other_users() |> Enum.map(&{&1.name, &1.id})
    disabled_users = auid |> Accounts.list_disabled_users() |> Enum.map(&{&1.name, &1.id})

    socket =
      assign(socket,
        user_disabled_success: false,
        user_enabled_success: false
      )
      |> assign_disable_user(users)
      |> assign_enable_user(disabled_users)

    {:ok, socket}
  end

  def handle_event("validate", %{"disable_user" => params}, socket) do
    {:noreply, assign(socket, select_disable: params["user"])}
  end

  def handle_event("validate", %{"enable_user" => params}, socket) do
    {:noreply, assign(socket, select_enable: params["user"])}
  end

  def handle_event("disable_user", %{"disable_user" => params}, socket) do
    user = Accounts.disable_user!(params["user"])

    new_user_list = Enum.reject(socket.assigns.user_list, fn {_name, id} -> id == user.id end)
    new_disabled_list = [{user.username, user.id} | socket.assigns.disabled_user_list]

    {:noreply,
     socket
     |> assign(user_disabled_success: true, user_enabled_success: false)
     |> assign_disable_user(new_user_list)
     |> assign_enable_user(new_disabled_list)}
  end

  def handle_event("enable_user", %{"enable_user" => params}, socket) do
    user = Accounts.enable_user!(params["user"])

    new_disabled_list =
      Enum.reject(socket.assigns.disabled_user_list, fn {_name, id} -> id == user.id end)

    new_user_list = [{user.username, user.id} | socket.assigns.user_list]

    {:noreply,
     socket
     |> assign(user_enabled_success: true, user_disabled_success: false)
     |> assign_enable_user(new_disabled_list)
     |> assign_disable_user(new_user_list)}
  end

  def handle_event("clear-enabled-flash", _params, socket) do
    {:noreply, assign(socket, user_enabled_success: false)}
  end

  def handle_event("clear-disabled-flash", _params, socket) do
    {:noreply, assign(socket, user_disabled_success: false)}
  end

  def assign_disable_user(socket, users) do
    case users do
      [] ->
        assign(socket, user_list: users, select_disable: nil)

      [{username, _id} | _] ->
        assign(socket, user_list: users, select_disable: username)
    end
  end

  def assign_enable_user(socket, users) do
    case users do
      [] ->
        assign(socket, disabled_user_list: users, select_enable: nil)

      [{username, _id} | _] ->
        assign(socket, disabled_user_list: users, select_enable: username)
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="text-2xl font-bold md:pl-8">Admin Panel</div>
      
    <!-- Disable user account -->
      <div class="text-2xl py-4 md:pl-8">Disable user account</div>
      <div class={settings_block(@current_user)}>
        <%= if @select_disable do %>
          <.form
            :let={f}
            for={:disable_user}
            id="admin-disable-user-form"
            phx-submit="disable_user"
            phx-change="validate"
            phx-target={@myself}
          >
            <p
              :if={@user_disabled_success}
              class="alert alert-info"
              id="user-disabled-ok"
              phx-click="clear-disabled-flash"
              phx-target={@myself}
            >
              User account successfully disabled.
            </p>

            <%!-- {label(f, :user, class: StyleHelpers.user_form_label(@current_user))} --%>
            <.input
              type="select"
              field={f[:user]}
              options={@user_list}
              class={StyleHelpers.user_form(@current_user)}
            />

            <div class="flex justify-end md:justify-center">
              <.button
                type="submit"
                data-confirm="Are you sure?"
                phx-disable-with="Disabling..."
                class={button_style(@current_user)}
                id="disable-user-button"
              >
                Disable User
              </.button>
            </div>
          </.form>
        <% else %>
          <p class="font-bold">There are no other users to disable!</p>
        <% end %>
      </div>
      
    <!-- Enable user account -->
      <div class="text-2xl py-4 md:pl-8">Re-enable user account</div>
      <div class={settings_block(@current_user)}>
        <%= if @select_enable do %>
          <.form
            :let={f}
            for={:enable_user}
            id="admin-enable-user-form"
            phx-submit="enable_user"
            phx-change="validate"
            phx-target={@myself}
          >
            <p
              :if={@user_enabled_success}
              class="alert alert-info"
              id="user-enabled-ok"
              phx-click="clear-enabled-flash"
              phx-target={@myself}
            >
              User account successfully re-enabled.
            </p>

            <%!-- {label(f, :user, class: StyleHelpers.user_form_label(@current_user))} --%>
            <.input
              type="select"
              field={f[:user]}
              options={@disabled_user_list}
              class={StyleHelpers.user_form(@current_user)}
            />

            <div class="flex justify-end md:justify-center">
              <.button
                type="submit"
                data-confirm="Are you sure?"
                phx-disable-with="Re-enabling..."
                class={button_style(@current_user)}
                id="enable-user-button"
              >
                Re-enable User
              </.button>
            </div>
          </.form>
        <% else %>
          <p class="font-bold">There are no disabled users!</p>
        <% end %>
      </div>
    </div>
    """
  end

  ## Tailwind styles

  def button_style(user) do
    [
      "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 rounded-md ",
      StyleHelpers.button_theme(user)
    ]
  end

  def settings_block(user) do
    ["px-4 py-8 mb-6 shadow rounded-lg md:mx-8 ", StyleHelpers.content_bubble_theme(user)]
  end
end
