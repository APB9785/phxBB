defmodule PhxBbWeb.UserRegistrationComponent do
  @moduledoc """
  Form for registering a new user.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers, only: [add_confirm_param: 1]
  import PhxBbWeb.StyleHelpers, only: [user_form_label: 1, user_form: 1, button_style: 1]

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User

  def mount(socket) do
    {:ok, assign(socket, changeset: Accounts.change_user_registration(%User{}))}
  end

  def handle_event("new_user", %{"user" => user_params}, socket) do
    params = Map.merge(user_params, defaults())

    case Accounts.register_user(params) do
      {:ok, user} ->
        Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)

        alert_message =
          "User created successfully. Please check your email for confirmation instructions."

        {
          :noreply,
          socket
          |> put_flash(:info, alert_message)
          |> redirect(to: Routes.user_session_path(socket, :new))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp defaults do
    %{"post_count" => 0, "title" => "Registered User", "theme" => "default", "admin" => false}
  end
end
