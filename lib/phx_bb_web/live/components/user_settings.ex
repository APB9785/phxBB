defmodule PhxBbWeb.UserSettings do
  @moduledoc """
  User settings page.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBbWeb.StyleHelpers

  def mount(socket) do
    {:ok,
     assign(socket,
       title_updated: false,
       timezone_updated: false,
       theme_updated: false,
       confirmation_resent: false,
       email_updated: false,
       avatar_updated: false,
       avatar_removed: false
     )}
  end

  def update(%{active_user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       email_changeset: Accounts.change_user_email(user),
       password_changeset: Accounts.change_user_password(user),
       tz_changeset: Accounts.change_user_timezone(user),
       title_changeset: Accounts.change_user_title(user),
       avatar_changeset: Accounts.change_user_avatar(user),
       theme_changeset: Accounts.change_user_theme(user)
     )}
  end

  def handle_event("resend_confirmation", _params, socket) do
    Accounts.deliver_user_confirmation_instructions(
      socket.assigns.active_user,
      &add_confirm_param/1
    )

    {:noreply, assign(socket, confirmation_resent: true)}
  end

  def handle_event("change_timezone", %{"user" => params}, socket) do
    case Accounts.update_user_timezone(socket.assigns.active_user, params) do
      {:ok, user} ->
        send(self(), {:updated_user, user})
        {:noreply, assign(socket, timezone_updated: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, tz_changeset: changeset)}
    end
  end

  def handle_event("change_password", params, socket) do
    user = socket.assigns.active_user

    case Accounts.update_user_password(user, params["current_password"], params["user"]) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password updated successfully.  Please log in again.")
         |> redirect(to: Routes.user_session_path(socket, :new))}

      {:error, changeset} ->
        {:noreply, assign(socket, password_changeset: changeset)}
    end
  end

  def handle_event("change_user_title", %{"user" => params}, socket) do
    case Accounts.update_user_title(socket.assigns.active_user, params) do
      {:ok, user} ->
        send(self(), {:updated_user, user})

        {:noreply, assign(socket, title_updated: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, title_changeset: changeset)}
    end
  end

  def handle_event("upload_avatar", _params, socket) do
    case consume_avatars(socket) do
      [] ->
        changeset =
          replace_error(socket.assigns.avatar_changeset, :avatar, "no file was selected")

        {:noreply, assign(socket, avatar_changeset: changeset)}

      [avatar_link] ->
        user = socket.assigns.active_user

        if user.avatar do
          path = Application.app_dir(:phx_bb, "priv/static") <> user.avatar
          File.rm(path)
        end

        {:ok, user} = Accounts.update_user_avatar(user, %{avatar: avatar_link})

        send(self(), {:updated_user, user})

        {:noreply,
         assign(socket,
           avatar_changeset: Accounts.change_user_avatar(%User{}),
           avatar_updated: true,
           avatar_removed: false
         )}
    end
  end

  def handle_event("update_email", params, socket) do
    user = socket.assigns.active_user

    case Accounts.apply_user_email(user, params["current_password"], params["user"]) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &add_confirm_email_param/1
        )

        changeset = Accounts.change_user_email(user)
        {:noreply, assign(socket, email_updated: true, email_changeset: changeset)}

      {:error, changeset} ->
        {:noreply, assign(socket, email_changeset: changeset)}
    end
  end

  def handle_event("validate_avatar", _params, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_avatar()
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, avatar_changeset: changeset)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("remove_avatar", _params, socket) do
    user = socket.assigns.active_user
    path = Application.app_dir(:phx_bb, "priv/static") <> user.avatar
    File.rm(path)
    {:ok, user} = Accounts.update_user_avatar(user, %{avatar: nil})

    send(self(), {:updated_user, user})

    {:noreply,
     assign(socket,
       avatar_changeset: Accounts.change_user_avatar(%User{}),
       avatar_removed: true,
       avatar_updated: false
     )}
  end

  def handle_event("change_user_theme", %{"user" => params}, socket) do
    case Accounts.update_user_theme(socket.assigns.active_user, params) do
      {:ok, user} ->
        send(self(), {:updated_theme, user})
        {:noreply, assign(socket, theme_updated: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, theme_changeset: changeset)}
    end
  end

  def handle_event("clear_flash", %{"flash" => message}, socket) do
    case message do
      "title_updated" -> {:noreply, assign(socket, title_updated: false)}
      "timezone_updated" -> {:noreply, assign(socket, timezone_updated: false)}
      "theme_updated" -> {:noreply, assign(socket, theme_updated: false)}
      "confirmation_resent" -> {:noreply, assign(socket, confirmation_resent: false)}
      "email_updated" -> {:noreply, assign(socket, email_updated: false)}
      "avatar_updated" -> {:noreply, assign(socket, avatar_updated: false)}
      "avatar_removed" -> {:noreply, assign(socket, avatar_removed: false)}
    end
  end

  # Helpers

  defp consume_avatars(socket) do
    consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
      name = filename(entry)
      dest = Path.join([:code.priv_dir(:phx_bb), "static", "uploads", name])
      File.cp!(path, dest)
      Routes.static_path(socket, "/uploads/#{name}")
      # dir = Application.app_dir(:phx_bb, "priv/static/uploads")
      # destination = Path.join([:code.priv_dir(:my_app), "static", "uploads", Path.basename(path)])
      #
      # File.cp!(meta.path, destination)
      #
      # Routes.static_path(socket, "/uploads/#{name}")
    end)
  end

  defp display_avatar_error({:avatar, {error, _}}), do: error

  defp filename(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end

  def add_confirm_param(token) do
    PhxBbWeb.Endpoint.url() <> "/forum?confirm=" <> token
  end

  def add_confirm_email_param(token) do
    PhxBbWeb.Endpoint.url() <> "/forum?confirm_email=" <> token
  end

  def replace_error(changeset, key, message, keys \\ []) when is_binary(message) do
    %{changeset | errors: [{key, {message, keys}}], valid?: false}
  end

  ## Tailwind Styles

  def confirmation_reminder_style(user) do
    ["md:mx-8 px-4 py-6 shadow rounded-lg ", confirmation_reminder_theme(user)]
  end

  def confirmation_reminder_theme(nil),
    do: confirmation_reminder_theme(%User{theme: StyleHelpers.default()})

  def confirmation_reminder_theme(%User{theme: "elixir"}), do: "bg-purple-200"
  def confirmation_reminder_theme(%User{theme: "dark"}), do: "bg-purple-900 text-gray-200"

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
