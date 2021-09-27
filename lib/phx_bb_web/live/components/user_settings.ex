defmodule PhxBbWeb.UserSettings do
  @moduledoc """
  User settings page.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBbWeb.StyleHelpers

  @s3_bucket "phxbb-demo-uploads"
  @region "us-east-2"

  def mount(socket) do
    {:ok,
     socket
     |> assign(
       title_updated: false,
       timezone_updated: false,
       theme_updated: false,
       confirmation_resent: false,
       email_updated: false,
       avatar_updated: false,
       avatar_removed: false
     )
     |> allow_upload(:avatar,
       accept: ~w(.png .jpeg .jpg),
       max_entries: 1,
       max_file_size: 100_000,
       external: &presign_upload/2
     )}
  end

  def update(%{active_user: user} = _assigns, socket) do
    {:ok,
     socket
     |> assign(
       active_user: user,
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

  def handle_event("change_user_theme", %{"user" => params}, socket) do
    case Accounts.update_user_theme(socket.assigns.active_user, params) do
      {:ok, user} ->
        send(self(), {:updated_theme, user})
        {:noreply, assign(socket, theme_updated: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, theme_changeset: changeset)}
    end
  end

  def handle_event("upload_avatar", _params, socket) do
    case uploaded_entries(socket, :avatar) do
      {[], []} ->
        changeset =
          replace_error(socket.assigns.avatar_changeset, :avatar, "no file was selected")

        {:noreply, assign(socket, avatar_changeset: changeset)}

      {[entry], []} ->
        user = socket.assigns.active_user

        # Delete previous avatar
        if user.avatar, do: s3_delete_avatar(user.avatar)

        avatar_link = Path.join(s3_url(), filename(entry))

        {:ok, user} = Accounts.update_user_avatar(user, %{avatar: avatar_link})

        consume_uploaded_entries(socket, :avatar, fn _, _ -> :ok end)

        send(self(), {:updated_user, user})

        {:noreply,
         assign(socket,
           avatar_changeset: Accounts.change_user_avatar(%User{}),
           avatar_updated: true,
           avatar_removed: false
         )}
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

    s3_delete_avatar(user.avatar)

    {:ok, user} = Accounts.update_user_avatar(user, %{avatar: nil})

    send(self(), {:updated_user, user})

    {:noreply,
     assign(socket,
       avatar_changeset: Accounts.change_user_avatar(%User{}),
       avatar_removed: true,
       avatar_updated: false
     )}
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

  defp s3_url, do: "//#{@s3_bucket}.s3.#{@region}.amazonaws.com"

  defp presign_upload(entry, socket) do
    uploads = socket.assigns.uploads
    key = filename(entry)

    config = %{
      region: @region,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }

    {:ok, fields} =
      PhxBb.SimpleS3Upload.sign_form_upload(config, @s3_bucket,
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads.avatar.max_file_size,
        expires_in: :timer.hours(1)
      )

    meta = %{
      uploader: "S3",
      key: key,
      url: s3_url(),
      fields: fields
    }

    {:ok, meta, socket}
  end

  def s3_delete_avatar(avatar_url) do
    [_, filename] = String.split(avatar_url, ".com/")

    ExAws.S3.delete_object(@s3_bucket, filename)
    |> ExAws.request!()
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
