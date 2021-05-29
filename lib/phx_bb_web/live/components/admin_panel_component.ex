defmodule PhxBbWeb.AdminPanelComponent do
  @moduledoc """
  Provides the Admin user(s) a UI for making changes to the forum.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.StyleHelpers,
    only: [settings_block: 1, user_form_label: 1, user_form: 1, button_style: 1]

  alias PhxBb.Accounts

  def mount(socket) do
    socket =
      assign(socket,
        confirm_disable: false,
        confirm_enable: false,
        user_disabled_success: false,
        user_enabled_success: false
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    auid = assigns.active_user.id
    users = Accounts.list_other_users(auid) |> Enum.map(&{&1.name, &1.id})
    disabled_users = Accounts.list_disabled_users(auid) |> Enum.map(&{&1.name, &1.id})

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign_disable_user(users)
      |> assign_enable_user(disabled_users)
    }
  end

  def handle_event("validate", %{"disable_user" => params}, socket) do
    choice = params["user"]
    socket = assign(socket, select_disable: choice)
    {:noreply, socket}
  end

  def handle_event("validate", %{"enable_user" => params}, socket) do
    choice = params["user"]
    socket = assign(socket, select_enable: choice)
    {:noreply, socket}
  end

  def handle_event("disable_user_prompt", _params, socket) do
    socket = assign(socket, confirm_disable: true)
    {:noreply, socket}
  end

  def handle_event("enable_user_prompt", _params, socket) do
    socket = assign(socket, confirm_enable: true)
    {:noreply, socket}
  end

  def handle_event("disable_user", %{"disable_user" => params}, socket) do
    {:ok, user} =
      params["user"] |> String.to_integer() |> Accounts.get_user!() |> Accounts.disable_user()

    Phoenix.PubSub.broadcast(PhxBb.PubSub, "accounts", {:user_disabled, user.id})

    new_user_list = Enum.reject(socket.assigns.user_list, fn {_name, id} -> id == user.id end)
    new_disabled_list = [{user.username, user.id} | socket.assigns.disabled_user_list]

    {
      :noreply,
      socket
      |> assign(user_disabled_success: true, confirm_disable: false)
      |> assign_disable_user(new_user_list)
      |> assign_enable_user(new_disabled_list)
    }
  end

  def handle_event("enable_user", %{"enable_user" => params}, socket) do
    {:ok, user} =
      params["user"] |> String.to_integer() |> Accounts.get_user!() |> Accounts.enable_user()

    Phoenix.PubSub.broadcast(PhxBb.PubSub, "accounts", {:user_enabled, user.id})

    new_disabled_list =
      Enum.reject(socket.assigns.disabled_user_list, fn {_name, id} -> id == user.id end)

    new_user_list = [{user.username, user.id} | socket.assigns.user_list]

    {
      :noreply,
      socket
      |> assign(user_enabled_success: true, confirm_enable: false)
      |> assign_enable_user(new_disabled_list)
      |> assign_disable_user(new_user_list)
    }
  end

  def handle_event("clear-enabled-flash", _params, socket) do
    {:noreply, assign(socket, user_enabled_success: false)}
  end

  def handle_event("clear-disabled-flash", _params, socket) do
    {:noreply, assign(socket, user_disabled_success: false)}
  end

  def assign_disable_user(socket, users) do
    assign(socket,
      user_list: users,
      select_disable: if(users == [], do: nil, else: hd(users) |> elem(0))
    )
  end

  def assign_enable_user(socket, users) do
    assign(socket,
      disabled_user_list: users,
      select_enable: if(users == [], do: nil, else: hd(users) |> elem(0))
    )
  end
end
