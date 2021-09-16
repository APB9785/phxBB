defmodule PhxBbWeb.UserRegistration do
  @moduledoc """
  Form for registering a new user.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBbWeb.StyleHelpers

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

  def add_confirm_param(token) do
    PhxBbWeb.Endpoint.url() <> "/forum?confirm=" <> token
  end

  defp defaults do
    %{"post_count" => 0, "title" => "Registered User", "theme" => "dark", "admin" => false}
  end

  def button_style(user) do
    [
      "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 rounded-md ",
      StyleHelpers.button_theme(user)
    ]
  end
end
