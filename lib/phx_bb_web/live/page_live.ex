defmodule PhxBbWeb.PageLive do
  @moduledoc """
  This is the main LiveView which renders the forum.
  """

  use PhxBbWeb, :live_view

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBbWeb.BoardComponent
  alias PhxBbWeb.BreadcrumbComponent
  alias PhxBbWeb.CreatePostComponent
  alias PhxBbWeb.MainIndexComponent
  alias PhxBbWeb.NewReplyComponent
  alias PhxBbWeb.PostComponent
  alias PhxBbWeb.UserMenuComponent
  alias PhxBbWeb.UserProfileComponent
  alias PhxBbWeb.UserRegistrationComponent

  def mount(_params, session, socket) do
    case lookup_token(session["user_token"]) do
      nil ->
        # User is logged out
        socket =
          socket
          |> assign(active_user: nil)
          |> assign(user_cache: %{})
          |> assign(bg_color: get_default_background())
          |> assign_defaults

        {:ok, socket}

      user ->
        # User is logged in
        socket =
          socket
          |> assign(bg_color: get_theme_background(user))
          |> assign(active_user: user)
          |> assign(user_cache: %{user.id => cache_self(user)})
          |> assign_defaults
          |> allow_upload(:avatar,
            accept: ~w(.png .jpeg .jpg),
            max_entries: 1,
            max_file_size: 100_000)

        {:ok, socket}
    end
  end

  def handle_params(%{"create_post" => "1", "board" => _}, _url, socket)
  when is_nil(socket.assigns.active_user) do
    socket = push_redirect(socket, to: "/users/log_in")
    {:noreply, socket}
  end
  def handle_params(%{"create_post" => "1", "board" => board_id}, _url, socket) do
    if active_assign_outdated?(:board, board_id, socket) do
      socket = assign_create_full_query(socket, board_id)
      {:noreply, socket}
    else  # No need to query database for Board info
      socket = assign(socket, [nav: :create_post, page_title: "Create Post"])
      {:noreply, socket}
    end
  end
  def handle_params(%{"post" => post_id}, _url, socket) do
    if active_assign_outdated?(:post, post_id, socket) do
      socket = assign_post_full_query(socket, post_id)
      {:noreply, socket}
    else  # No need to query database for Post info
      socket = assign_post_nav(socket, socket.assigns.active_post)
      {:noreply, socket}
    end
  end
  def handle_params(%{"board" => board_id}, _url, socket) do
    if active_assign_outdated?(:board, board_id, socket) do
      socket = assign_board_full_query(socket, board_id)
      {:noreply, socket}
    else  # No need to query database for Board info
      socket = assign(socket, [nav: :board, page_title: socket.assigns.active_board.name])
      {:noreply, socket}
    end
  end
  def handle_params(%{"user" => user_id}, _url, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        socket = assign_invalid(socket)
        {:noreply, socket}
      user ->
        socket = assign(socket, [nav: :user_profile, page_title: user.username, view_user: user])
        {:noreply, socket}
    end
  end
  def handle_params(%{"register" => "1"}, _url, socket) do
    if is_nil(socket.assigns.active_user) do
      socket = assign(socket, [nav: :register, page_title: "Register"])
      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(:info, "You are already registered and logged in.")
        |> push_patch(to: Routes.live_path(socket, __MODULE__))
      {:noreply, socket}
    end
  end
  def handle_params(%{"settings" => "1"}, _url, socket) do
    socket = settings_loader(socket)
    {:noreply, socket}
  end
  def handle_params(%{"confirm" => token}, _url, socket) do
    # Do not log in the user after confirmation to avoid a
    # leaked token giving the user access to the account.
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Account confirmed successfully.")
          |> redirect(to: "/users/log_in")
        {:noreply, socket}

      :error ->
        socket = user_confirm_error_redirect(socket)
        {:noreply, socket}
    end
  end
  def handle_params(%{"confirm_email" => token}, _url, socket) do
    case Accounts.update_user_email(socket.assigns.active_user, token) do
      :ok ->
        socket =
          socket
          |> put_flash(:info, "Email changed successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__))
        {:noreply, socket}

      :error ->
        socket =
          socket
          |> put_flash(:error, "Email change link is invalid or it has expired.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__))
        {:noreply, socket}
    end
  end
  def handle_params(params, _url, socket) when params == %{} do
    socket = assign(socket, [nav: :main, page_title: "Board Index"])
    {:noreply, socket}
  end
  def handle_params(_params, _url, socket) do
    socket = assign_invalid(socket)
    {:noreply, socket}
  end

  def handle_event("resend_verification", _params, socket) do
    user = socket.assigns.active_user
    Accounts.deliver_user_confirmation_instructions(user, &add_confirm_param/1)

    socket =
      put_flash(socket, :info,
        "Confirmation instructions re-sent.  Please check your email.")

    {:noreply, socket}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.active_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(applied_user, user.email, &add_confirm_email_param/1)

        socket =
          socket
          |> put_flash(:info, "A link to confirm your email change has been sent to the new address.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, email_changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("change_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.active_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "Password updated successfully.  Please log in again.")
          |> redirect(to: Routes.user_session_path(socket, :new))

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, password_changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("change_timezone", %{"user" => params}, socket) do
    user = socket.assigns.active_user

    case Accounts.update_user_timezone(user, params) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "Timezone updated successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, tz_changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("change_user_title", %{"user" => params}, socket) do
    user = socket.assigns.active_user

    case Accounts.update_user_title(user, params) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "User title updated successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, title_changeset: changeset)
        {:noreply, socket}
    end
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

  def handle_event("validate_avatar", _params, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_avatar
      |> Map.put(:action, :insert)

    socket = assign(socket, avatar_changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    socket =
      socket
      |> cancel_upload(:avatar, ref)
      |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))

    {:noreply, socket}
  end

  def handle_event("remove_avatar", _params, socket) do
    remove_avatar(socket.assigns.active_user)

    socket =
      socket
      |> assign(avatar_changeset: Accounts.change_user_avatar(%User{}))
      |> put_flash(:info, "User avatar removed successfully.")
      |> push_redirect(to: Routes.live_path(socket, PhxBbWeb.PageLive, settings: 1))

    {:noreply, socket}
  end

  def handle_event("change_user_theme", %{"user" => params}, socket) do
    user = socket.assigns.active_user

    case Accounts.update_user_theme(user, params) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "Theme changed successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:info, "You are already using that theme.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))

        {:noreply, socket}
    end
  end

  defp settings_loader(socket) do
    case socket.assigns.active_user do
      nil ->
        push_redirect(socket, to: "/users/log_in")
      user ->
        socket
        |> assign(nav: :settings)
        |> assign(page_title: "User Settings")
        |> assign(email_changeset: Accounts.change_user_email(user))
        |> assign(password_changeset: Accounts.change_user_password(user))
        |> assign(tz_changeset: Accounts.change_user_timezone(user))
        |> assign(title_changeset: Accounts.change_user_title(user))
        |> assign(avatar_changeset: Accounts.change_user_avatar(user))
        |> assign(theme_changeset: Accounts.change_user_theme(user))
    end
  end

  defp copy_avatar_links(socket) do
    consume_uploaded_entries(socket, :avatar, fn meta, entry ->
      uploads_dir = Application.app_dir(:phx_bb, "priv/static/uploads")
      dest = Path.join(uploads_dir, filename(entry))
      File.cp!(meta.path, dest)
      Routes.static_path(socket, "/uploads/#{filename(entry)}")
    end)
  end

  defp upload_avatar(socket, avatar_link) do
    user = socket.assigns.active_user

    # If the user is replacing an existing avatar, delete the old file
    if user.avatar, do: File.rm!("priv/static#{user.avatar}")

    case Accounts.update_user_avatar(user, %{avatar: avatar_link}) do
      {:ok, _user} ->
        socket
        |> assign(avatar_changeset: Accounts.change_user_avatar(%User{}))
        |> put_flash(:info, "User avatar updated successfully.")
        |> push_redirect(to: Routes.live_path(socket, PhxBbWeb.PageLive, settings: 1))

      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, avatar_changeset: changeset)
    end
  end
end
