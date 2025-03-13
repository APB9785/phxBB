defmodule PhxBbWeb.UserSettings do
  @moduledoc """
  User settings page. (OLD)
  """
  use PhxBbWeb, :live_view

  alias PhxBb.Accounts
  alias PhxBbWeb.StyleHelpers

  def handle_event("change_timezone", %{"user" => params}, socket) do
    case Accounts.update_user_timezone(socket.assigns.current_user, params) do
      {:ok, user} ->
        send(self(), {:updated_user, user})
        {:noreply, assign(socket, timezone_updated: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, tz_changeset: changeset)}
    end
  end

  def handle_event("change_password", params, socket) do
    user = socket.assigns.current_user

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
    case Accounts.update_user_title(socket.assigns.current_user, params) do
      {:ok, user} ->
        send(self(), {:updated_user, user})

        {:noreply, assign(socket, title_updated: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, title_changeset: changeset)}
    end
  end

  def handle_event("change_user_theme", %{"user" => params}, socket) do
    case Accounts.update_user_theme(socket.assigns.current_user, params) do
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

  def render(assigns) do
    ~H"""
    <div>
      <!-- Change Timezone -->
      <div class="text-2xl py-4 md:pl-8">Change timezone</div>
      <div class={settings_block(@current_user)}>
        <.form
          :let={f}
          for={to_form(@tz_changeset)}
          id="change-user-timezone-form"
          phx_submit="change_timezone"
          phx_target={@myself}
        >
          <%= if @tz_changeset.action do %>
            <div class="alert alert-danger">
              <p>Oops, something went wrong! Please check the errors below.</p>
            </div>
          <% end %>
          <%= if @timezone_updated do %>
            <p
              class="alert alert-info"
              id="timezone-updated-ok"
              phx-click="clear_flash"
              phx-value-flash="timezone_updated"
              phx-target={@myself}
            >
              Timezone updated successfully.
            </p>
          <% end %>

          {label(f, :timezone, class: StyleHelpers.user_form_label(@current_user))}
          {select(f, :timezone, Tzdata.zone_list(), class: StyleHelpers.user_form(@current_user))}
          {error_tag(f, :timezone)}

          {submit("Change timezone",
            phx_disable_with: "Changing...",
            class: button_style(@current_user)
          )}
        </.form>
      </div>
      
    <!-- Change user title -->
      <div class="text-2xl py-4 md:pl-8">Change user title</div>
      <div class={settings_block(@current_user)}>
        <.form
          :let={f}
          for={to_form(@title_changeset)}
          id="change-user-title-form"
          phx_submit="change_user_title"
          phx_target={@myself}
        >
          <%= if @title_changeset.action do %>
            <div class="alert alert-danger" id="title-update-failed">
              <p>Oops, something went wrong! Please check the errors below.</p>
            </div>
          <% end %>
          <%= if @title_updated do %>
            <p
              class="alert alert-info"
              id="title-updated-ok"
              phx-click="clear_flash"
              phx-value-flash="title_updated"
              phx-target={@myself}
            >
              User title updated successfully.
            </p>
          <% end %>

          {label(f, :title, class: StyleHelpers.user_form_label(@current_user))}
          {text_input(f, :title, class: StyleHelpers.user_form(@current_user))}
          {error_tag(f, :title)}

          {submit("Change user title",
            phx_disable_with: "Changing...",
            class: button_style(@current_user)
          )}
        </.form>
      </div>
      
    <!-- Change theme -->
      <div class="text-2xl py-4 md:pl-8">Change theme</div>
      <div class={settings_block(@current_user)}>
        <.form
          :let={f}
          for={to_form(@theme_changeset)}
          id="change-user-theme-form"
          phx_submit="change_user_theme"
          phx_target={@myself}
        >
          <%= if @theme_changeset.action do %>
            <div class="alert alert-danger" id="theme-change-failed">
              <p>Oops, something went wrong! Please check the errors below.</p>
            </div>
          <% end %>
          <%= if @theme_updated do %>
            <p
              class="alert alert-info"
              id="theme-changed-ok"
              phx-click="clear_flash"
              phx-value-flash="theme_updated"
              phx-target={@myself}
            >
              Theme updated successfully.
            </p>
          <% end %>

          {label(f, :theme, class: StyleHelpers.user_form_label(@current_user))}
          {select(f, :theme, StyleHelpers.theme_list(), class: StyleHelpers.user_form(@current_user))}
          {error_tag(f, :theme)}

          {submit("Change theme",
            phx_disable_with: "Changing...",
            class: button_style(@current_user)
          )}
        </.form>
      </div>
      
    <!-- Change avatar -->
      <div class="text-2xl py-4 md:pl-8">Change avatar</div>
      <div class={settings_block(@current_user)}>
        <%= if @avatar_updated do %>
          <p
            class="alert alert-info"
            id="avatar-updated-ok"
            phx-click="clear_flash"
            phx-value-flash="avatar_updated"
            phx-target={@myself}
          >
            User avatar updated successfully.
          </p>
        <% end %>
        <%= if @avatar_removed do %>
          <p
            class="alert alert-info"
            id="avatar-removed-ok"
            phx-click="clear_flash"
            phx-value-flash="avatar_removed"
            phx-target={@myself}
          >
            User avatar removed successfully.
          </p>
        <% end %>
        
    <!-- Current avatar display -->
        <div class="w-32">
          <img src={@current_user.avatar} class="max-h-40 w-full object-fill pb-4" />
        </div>
        <%= if @current_user.avatar do %>
          <button
            id="remove-avatar-link"
            phx-target={@myself}
            phx-click="remove_avatar"
            class={[StyleHelpers.link_style(@current_user), " pb-4"]}
          >
            Remove current avatar
          </button>
        <% end %>

        <.form
          for={to_form(@avatar_changeset)}
          id="change-user-avatar-form"
          phx_submit="upload_avatar"
          phx_target={@myself}
          phx_change="validate_avatar"
        >
          <div class="border-2 p-2 md:w-1/4" phx-drop-target={@uploads.avatar.ref}>
            {live_file_input(@uploads.avatar)}
          </div>
          <div id="hint">
            (max {trunc(@uploads.avatar.max_file_size / 1_000)} KB)
          </div>

          <%= for {_ref, err} <- @uploads.avatar.errors do %>
            <div class="error text-red-500">
              {humanize(err)}
            </div>
          <% end %>

          <%= for entry <- @uploads.avatar.entries do %>
            <div class="entry" id="avatar-preview">
              <div class="w-32">
                {live_img_preview(entry, class: "max-h-40 w-full object-fill")}
              </div>

              <div id="progress">
                <div id="progress-value">
                  {entry.progress}%
                </div>
                <div id="progress-bar">
                  <span style={"w-#{entry.progress}%"}></span>
                </div>
              </div>

              <a
                href="#"
                phx-click="cancel_upload"
                phx-value-ref={entry.ref}
                phx-target={@myself}
                id="cancel-upload"
              >
                &times;
              </a>
            </div>
          <% end %>

          <%= for error <- @avatar_changeset.errors do %>
            <div class="text-red-500 pt-2" id="avatar-submit-error">
              {display_avatar_error(error)}
            </div>
          <% end %>

          {submit("Upload avatar",
            phx_disable_with: "Uploading...",
            class: button_style(@current_user),
            id: "submit-user-avatar-upload"
          )}
        </.form>
      </div>
      
    <!-- Change Email -->
      <div class="text-2xl py-4 md:pl-8">Change email</div>
      <div class={settings_block(@current_user)}>
        <.form
          :let={f}
          for={to_form(@email_changeset)}
          id="update-user-email-form"
          phx_submit="update_email"
          phx_target={@myself}
        >
          <%= if @email_changeset.action do %>
            <div class="alert alert-danger">
              <p>Oops, something went wrong! Please check the errors below.</p>
            </div>
          <% end %>
          <%= if @email_updated do %>
            <p
              class="alert alert-info"
              id="email-updated-ok"
              phx-click="clear_flash"
              phx-value-flash="email_updated"
              phx-target={@myself}
            >
              A link to confirm your email change has been sent to the new address.
            </p>
          <% end %>

          {hidden_input(f, :action, name: "action", value: "update_email")}

          {label(f, :email, class: StyleHelpers.user_form_label(@current_user))}
          {email_input(f, :email,
            required: true,
            class: StyleHelpers.user_form(@current_user)
          )}
          {error_tag(f, :email)}

          {label(f, :current_password,
            for: "current_password_for_email",
            class: StyleHelpers.user_form_label(@current_user)
          )}
          {password_input(f, :current_password,
            required: true,
            name: "current_password",
            id: "current_password_for_email",
            class: StyleHelpers.user_form(@current_user)
          )}
          {error_tag(f, :current_password)}

          {submit("Change email",
            phx_disable_with: "Changing...",
            class: button_style(@current_user)
          )}
        </.form>
      </div>
      
    <!-- Change password -->
      <div class="text-2xl py-4 md:pl-8">Change password</div>
      <div class={settings_block(@current_user)}>
        <.form
          :let={f}
          for={to_form(@password_changeset)}
          id="change-user-password-form"
          phx_submit="change_password"
          phx_target={@myself}
        >
          <%= if @password_changeset.action do %>
            <div class="alert alert-danger">
              <p>Oops, something went wrong! Please check the errors below.</p>
            </div>
          <% end %>

          {hidden_input(f, :action, name: "action", value: "update_password")}

          {label(f, :password, "New password", class: StyleHelpers.user_form_label(@current_user))}
          {password_input(f, :password,
            required: true,
            class: StyleHelpers.user_form(@current_user)
          )}
          {error_tag(f, :password)}

          {label(f, :password_confirmation, "Confirm new password",
            class: StyleHelpers.user_form_label(@current_user)
          )}
          {password_input(f, :password_confirmation,
            required: true,
            class: StyleHelpers.user_form(@current_user)
          )}
          {error_tag(f, :password_confirmation)}

          {label(f, :current_password,
            for: "current_password_for_password",
            class: StyleHelpers.user_form_label(@current_user)
          )}
          {password_input(f, :current_password,
            required: true,
            name: "current_password",
            id: "current_password_for_password",
            class: StyleHelpers.user_form(@current_user)
          )}
          {error_tag(f, :current_password)}

          {submit("Change password",
            phx_disable_with: "Changing...",
            class: button_style(@current_user)
          )}
        </.form>
      </div>
    </div>
    """
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
