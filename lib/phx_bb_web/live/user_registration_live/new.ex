defmodule PhxBbWeb.UserRegistrationLive.New do
  use Phoenix.LiveView

  alias PhxBbWeb.Router.Helpers, as: Routes
  alias PhxBb.Accounts
  alias PhxBb.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, assign(socket, changeset: changeset)}
  end

  def render(assigns), do: Phoenix.View.render(PhxBbWeb.UserRegistrationView, "new.html", assigns)

  # def handle_event("validate", %{"user" => user_params}, socket) do
  #   changeset = PhxBb.Accounts.change_user_registration(%User{}, user_params)
  #
  #   {:noreply, assign(socket, changeset: changeset)}
  # end

  def handle_event("save", %{"user" => user_params}, socket) do
    lower = Map.get(user_params, "username") |> String.downcase
    user_params =
      user_params
      |> Map.put("lowercase", lower)
      |> Map.put("post_count", 0)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # {:ok, _} = Accounts.deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(socket, :confirm, &1))

        {:noreply,
          socket
          |> put_flash(:info, "User created successfully. Please check your email for confirmation instructions.")
          |> redirect(to: Routes.user_session_path(socket, :new))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
