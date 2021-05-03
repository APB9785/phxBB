defmodule PhxBbWeb.UserSettingsComponent do
  @moduledoc """
  User settings page.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User

  def mount(socket) do
    socket =
      assign(socket,
        title_updated: false,
        timezone_updated: false,
        theme_updated: false,
        confirmation_resent: false,
        email_updated: false,
        avatar_updated: false,
        avatar_removed: false)

    {:ok, socket}
  end

  def update(assigns, socket) do
    user = assigns.active_user
    socket =
      socket
      |> assign(assigns)
      |> assign(
        email_changeset: Accounts.change_user_email(user),
        password_changeset: Accounts.change_user_password(user),
        tz_changeset: Accounts.change_user_timezone(user),
        title_changeset: Accounts.change_user_title(user),
        avatar_changeset: Accounts.change_user_avatar(user),
        theme_changeset: Accounts.change_user_theme(user))

    {:ok, socket}
  end

  def handle_event("resend_confirmation", _params, socket) do
    user = socket.assigns.active_user
    Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)
    socket = assign(socket, confirmation_resent: true)

    {:noreply, socket}
  end

  def handle_event("change_timezone", %{"user" => params}, socket) do
    socket = assign_change_timezone(socket, params)
    {:noreply, socket}
  end

  def handle_event("change_password", params, socket) do
    socket = assign_change_password(socket, params)
    {:noreply, socket}
  end

  def handle_event("change_user_title", %{"user" => params}, socket) do
    socket = assign_change_title(socket, params)
    {:noreply, socket}
  end

  def handle_event("upload_avatar", _params, socket) do
    case copy_avatar_links(socket) do
      [] ->
        socket = assign(socket, avatar_changeset: no_file_error(socket))
        {:noreply, socket}

      [avatar_link] ->
        socket = upload_avatar(socket, avatar_link)
        {:noreply, socket}
    end
  end

  def handle_event("update_email", params, socket) do
    socket = assign_update_email(socket, params)
    {:noreply, socket}
  end

  def handle_event("validate_avatar", _params, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_avatar
      |> Map.put(:action, :insert)

    socket = assign(socket, avatar_changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    socket = cancel_upload(socket, :avatar, ref)
    {:noreply, socket}
  end

  def handle_event("remove_avatar", _params, socket) do
    socket = assign_remove_avatar(socket)
    {:noreply, socket}
  end

  def handle_event("change_user_theme", %{"user" => params}, socket) do
    socket = assign_change_theme(socket, params)
    {:noreply, socket}
  end

  defp upload_avatar(socket, avatar_link) do
    user = socket.assigns.active_user

    # If the user is replacing an existing avatar, delete the old file
    if user.avatar, do: Application.app_dir(:phx_bb, "priv/static") <> user.avatar |> File.rm!

    # Update DB with new avatar link
    {:ok, user} = Accounts.update_user_avatar(user, %{avatar: avatar_link})

    # Update active_user assign
    send(self(), {:updated_user, user})

    # Broadcast the new avatar to other users to update their caches
    message = {:user_avatar_change, user.id, user.avatar}
    Phoenix.PubSub.broadcast(PhxBb.PubSub, "accounts", message)

    assign(socket,
      avatar_changeset: Accounts.change_user_avatar(%User{}),
      avatar_updated: true,
      avatar_removed: false)
  end

  defp copy_avatar_links(socket) do
    consume_uploaded_entries(socket, :avatar, fn meta, entry ->
      uploads_dir = Application.app_dir(:phx_bb, "priv/static/uploads")
      dest = Path.join(uploads_dir, filename(entry))
      File.cp!(meta.path, dest)
      Routes.static_path(socket, "/uploads/#{filename(entry)}")
    end)
  end

  defp assign_change_title(socket, params) do
    case Accounts.update_user_title(socket.assigns.active_user, params) do
      {:ok, user} ->
        send(self(), {:updated_user, user})
        assign(socket, title_updated: true)

      {:error, changeset} ->
        assign(socket, title_changeset: changeset)
    end
  end

  defp assign_change_timezone(socket, params) do
    case Accounts.update_user_timezone(socket.assigns.active_user, params) do
      {:ok, user} ->
        send(self(), {:updated_user, user})
        assign(socket, timezone_updated: true)

      {:error, changeset} ->
        assign(socket, tz_changeset: changeset)
    end
  end

  defp assign_change_theme(socket, params) do
    case Accounts.update_user_theme(socket.assigns.active_user, params) do
      {:ok, user} ->
        send(self(), {:updated_theme, user})
        assign(socket, theme_updated: true)

      {:error, changeset} ->
        assign(socket, theme_changeset: changeset)
    end
  end

  defp assign_update_email(socket, %{"current_password" => password, "user" => user_params}) do
    user = socket.assigns.active_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(applied_user, user.email,
          &add_confirm_email_param/1)
        changeset = Accounts.change_user_email(user)
        assign(socket, email_updated: true, email_changeset: changeset)

      {:error, changeset} ->
        assign(socket, email_changeset: changeset)
    end
  end

  defp assign_change_password(socket, params) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.active_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, _user} ->
        socket
        |> put_flash(:info, "Password updated successfully.  Please log in again.")
        |> redirect(to: Routes.user_session_path(socket, :new))

      {:error, changeset} ->
        assign(socket, password_changeset: changeset)
    end
  end

  defp assign_remove_avatar(socket) do
    user = socket.assigns.active_user
    Application.app_dir(:phx_bb, "priv/static") <> user.avatar |> File.rm!
    {:ok, user} = Accounts.update_user_avatar(user, %{avatar: nil})

    # Update active_user assign
    send(self(), {:updated_user, user})

    # Broadcast the new avatar to other users to update their caches
    message = {:user_avatar_change, user.id, user.avatar}
    Phoenix.PubSub.broadcast(PhxBb.PubSub, "accounts", message)

    assign(socket,
      avatar_changeset: Accounts.change_user_avatar(%User{}),
      avatar_removed: true,
      avatar_updated: false)
  end
end
