defmodule PhxBbWeb.UserRegistrationComponent do
  @moduledoc """
  Form for registering a new user.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User

  def mount(socket) do
    socket = assign(socket, changeset: Accounts.change_user_registration(%User{}))
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def handle_event("new_user", %{"user" => user_params}, socket) do
    socket =
      user_params
      |> Map.put("post_count", 0)
      |> Map.put("title", "Registered User")
      |> Map.put("theme", "default")
      |> Map.put("admin", false)
      |> register_new_user(socket)

    {:noreply, socket}
  end

  defp register_new_user(user_params, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)

        alert_message =
          "User created successfully. Please check your email for confirmation instructions."

        socket
        |> put_flash(:info, alert_message)
        |> redirect(to: Routes.user_session_path(socket, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, changeset: changeset)
    end
  end
end
