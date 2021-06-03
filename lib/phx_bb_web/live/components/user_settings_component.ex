defmodule PhxBbWeb.UserSettingsComponent do
  @moduledoc """
  User settings page.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers,
    only: [add_confirm_param: 1, add_confirm_email_param: 1, replace_error: 3]

  import PhxBbWeb.StyleHelpers,
    only: [
      confirmation_reminder_style: 1,
      button_style: 1,
      settings_block: 1,
      user_form_label: 1,
      user_form: 1,
      theme_list: 0,
      link_style: 1
    ]

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User

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

  def update(assigns, socket) do
    user = assigns.active_user

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
    socket.assigns.active_user
    |> Accounts.deliver_user_confirmation_instructions(&add_confirm_param/1)

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

        message = {:user_title_change, user.id, user.title}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "accounts", message)

        {:noreply, assign(socket, title_updated: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, title_changeset: changeset)}
    end
  end

  def handle_event("upload_avatar", _params, socket) do
    case consume_avatars(socket) do
      [] ->
        {:noreply,
         socket.assigns.avatar_changeset
         |> replace_error(:avatar, "no file was selected")
         |> then(&assign(socket, avatar_changeset: &1))}

      [avatar_link] ->
        user = socket.assigns.active_user

        if user.avatar,
          do: (Application.app_dir(:phx_bb, "priv/static") <> user.avatar) |> File.rm()

        {:ok, user} = Accounts.update_user_avatar(user, %{avatar: avatar_link})

        send(self(), {:updated_user, user})

        message = {:user_avatar_change, user.id, user.avatar}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "accounts", message)

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
    (Application.app_dir(:phx_bb, "priv/static") <> user.avatar) |> File.rm()
    {:ok, user} = Accounts.update_user_avatar(user, %{avatar: nil})

    send(self(), {:updated_user, user})

    message = {:user_avatar_change, user.id, user.avatar}
    Phoenix.PubSub.broadcast(PhxBb.PubSub, "accounts", message)

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
    consume_uploaded_entries(socket, :avatar, fn meta, entry ->
      Application.app_dir(:phx_bb, "priv/static/uploads")
      |> Path.join(filename(entry))
      |> then(&File.cp!(meta.path, &1))

      Routes.static_path(socket, "/uploads/#{filename(entry)}")
    end)
  end

  defp display_avatar_error({:avatar, {error, _}}), do: error

  defp filename(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end
end
