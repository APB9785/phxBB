defmodule PhxBbWeb.UserRegistrationController do
  use PhxBbWeb, :controller

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBbWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    lower = Map.get(user_params, "username") |> String.downcase
    user_params =
      user_params
      |> Map.put("lowercase", lower)
      |> Map.put("post_count", 0)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
