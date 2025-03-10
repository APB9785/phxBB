defmodule PhxBbWeb.UserSettingsLive do
  use PhxBbWeb, :live_view

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User

  @s3_bucket "phxbb-demo-uploads"
  @region "us-east-2"

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div :if={is_nil(@current_user.confirmed_at)} class={confirmation_reminder_style(@current_user)}>

        <p
          :if={@confirmation_resent}
          class="alert alert-info"
          id="confirmation-resent-ok"
          phx-click="clear_flash"
          phx-value-flash="confirmation_resent"
          phx-target={@myself}
        >
          Confirmation instructions re-sent.
        </p>
      <div class="pb-4">
        Please confirm your account by clicking the link in your email.
        Be sure to check the "Promotions" folder if you use gmail.
      </div>
      <div>Current Email: {@current_user.email}</div>
      <button
        phx-click="resend_confirmation"
        class={button_style(@current_user)}
        id="resend-verification-button"
      >
        Re-send confirmation link
      </button>
    </div>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(
        current_password: nil,
        email_form_current_password: nil,
        current_email: user.email,
        email_form: to_form(email_changeset),
        password_form: to_form(password_changeset),
        trigger_submit: false,
        title_updated: false,
       timezone_updated: false,
       theme_updated: false,
       confirmation_resent: false,
       email_updated: false,
       avatar_updated: false,
       avatar_removed: false,
       email_changeset: Accounts.change_user_email(user),
       password_changeset: Accounts.change_user_password(user),
       tz_changeset: Accounts.change_user_timezone(user),
       title_changeset: Accounts.change_user_title(user),
       avatar_changeset: Accounts.change_user_avatar(user),
       theme_changeset: Accounts.change_user_theme(user)
        )
        |> allow_upload(:avatar,
       accept: ~w(.png .jpeg .jpg),
       max_entries: 1,
       max_file_size: 100_000,
       external: &presign_upload/2
     )

    {:ok, socket}
  end

  def handle_event("resend_confirmation", _params, socket) do
    Accounts.deliver_user_confirmation_instructions(
      socket.assigns.active_user,
      &add_confirm_param/1
    )

    {:noreply, assign(socket, confirmation_resent: true)}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
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
