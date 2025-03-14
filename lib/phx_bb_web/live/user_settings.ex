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
        >
          <div :if={@tz_changeset.action} class="alert alert-danger">
            <p>Oops, something went wrong! Please check the errors below.</p>
          </div>
          <p
            :if={@timezone_updated}
            class="alert alert-info"
            id="timezone-updated-ok"
            phx-click="clear_flash"
            phx-value-flash="timezone_updated"
          >
            Timezone updated successfully.
          </p>

          <%!-- {label(f, :timezone, class: StyleHelpers.user_form_label(@current_user))} --%>
          <.input
            type="select"
            field={f[:timezone]}
            options={Tzdata.zone_list()}
            class={StyleHelpers.user_form(@current_user)}
          />
          <%!-- {error_tag(f, :timezone)} --%>

          <.button type="submit" phx-disable-with="Changing..." class={button_style(@current_user)}>
            Change timezone
          </.button>
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
          <div :if={@title_changeset.action} class="alert alert-danger" id="title-update-failed">
            <p>Oops, something went wrong! Please check the errors below.</p>
          </div>
          <p
            :if={@title_updated}
            class="alert alert-info"
            id="title-updated-ok"
            phx-click="clear_flash"
            phx-value-flash="title_updated"
          >
            User title updated successfully.
          </p>

          <%!-- {label(f, :title, class: StyleHelpers.user_form_label(@current_user))} --%>
          <.input type="text" field={f[:title]} class={StyleHelpers.user_form(@current_user)} />
          <%!-- {error_tag(f, :title)} --%>

          <.button type="submit" phx-disable-with="Changing..." class={button_style(@current_user)}>
            Change user title
          </.button>
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
        >
          <div :if={@theme_changeset.action} class="alert alert-danger" id="theme-change-failed">
            <p>Oops, something went wrong! Please check the errors below.</p>
          </div>
          <p
            :if={@theme_updated}
            class="alert alert-info"
            id="theme-changed-ok"
            phx-click="clear_flash"
            phx-value-flash="theme_updated"
          >
            Theme updated successfully.
          </p>

          <%!-- {label(f, :theme, class: StyleHelpers.user_form_label(@current_user))} --%>
          <.input
            type="select"
            field={f[:theme]}
            options={StyleHelpers.theme_list()}
            class={StyleHelpers.user_form(@current_user)}
          />
          <%!-- {error_tag(f, :theme)} --%>

          <.button type="submit" phx-disable-with="Changing..." class={button_style(@current_user)}>
            Change theme
          </.button>
        </.form>
      </div>
      
    <!-- Change avatar -->
      <div class="text-2xl py-4 md:pl-8">Change avatar</div>
      <div class={settings_block(@current_user)}>
        <p
          :if={@avatar_updated}
          class="alert alert-info"
          id="avatar-updated-ok"
          phx-click="clear_flash"
          phx-value-flash="avatar_updated"
        >
          User avatar updated successfully.
        </p>
        <p
          :if={@avatar_removed}
          class="alert alert-info"
          id="avatar-removed-ok"
          phx-click="clear_flash"
          phx-value-flash="avatar_removed"
        >
          User avatar removed successfully.
        </p>
        
    <!-- Current avatar display -->
        <div class="w-32">
          <img src={@current_user.avatar} class="max-h-40 w-full object-fill pb-4" />
        </div>
        <button
          :if={@current_user.avatar}
          id="remove-avatar-link"
          phx-click="remove_avatar"
          class={[StyleHelpers.link_style(@current_user), "pb-4"]}
        >
          Remove current avatar
        </button>

        <.form
          for={to_form(@avatar_changeset)}
          id="change-user-avatar-form"
          phx_submit="upload_avatar"
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

          <div :for={entry <- @uploads.avatar.entries} class="entry" id="avatar-preview">
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

            <a href="#" phx-click="cancel_upload" phx-value-ref={entry.ref} id="cancel-upload">
              &times;
            </a>
          </div>

          <div
            :for={error <- @avatar_changeset.errors}
            class="text-red-500 pt-2"
            id="avatar-submit-error"
          >
            {display_avatar_error(error)}
          </div>

          <.button
            type="submit"
            phx-disable-with="Uploading..."
            class={button_style(@current_user)}
            id="submit-user-avatar-upload"
          >
            Upload avatar
          </.button>
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
        >
          <div :if={@email_changeset.action} class="alert alert-danger">
            <p>Oops, something went wrong! Please check the errors below.</p>
          </div>
          <p
            :if={@email_updated}
            class="alert alert-info"
            id="email-updated-ok"
            phx-click="clear_flash"
            phx-value-flash="email_updated"
          >
            A link to confirm your email change has been sent to the new address.
          </p>

          <.input type="hidden" name="action" value="update_email" />

          <%!-- {label(f, :email, class: StyleHelpers.user_form_label(@current_user))} --%>
          <.input
            type="email"
            field={f[:email]}
            required
            class={StyleHelpers.user_form(@current_user)}
          />
          <%!-- {error_tag(f, :email)} --%>

          <%!-- {label(f, :current_password,
            for: "current_password_for_email",
            class: StyleHelpers.user_form_label(@current_user)
          )} --%>
          <.input
            type="password"
            field={f[:current_password]}
            required
            id="current_password_for_email"
            class={StyleHelpers.user_form(@current_user)}
          />
          <%!-- {error_tag(f, :current_password)} --%>

          <.button type="submit" phx-disable-with="Changing..." class={button_style(@current_user)}>
            Change email
          </.button>
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
        >
          <div :if={@password_changeset.action} class="alert alert-danger">
            <p>Oops, something went wrong! Please check the errors below.</p>
          </div>

          <.input type="hidden" name="action" value="update_password" />

          <%!-- {label(f, :password, "New password", class: StyleHelpers.user_form_label(@current_user))} --%>
          <.input
            type="password"
            field={f[:password]}
            required
            class={StyleHelpers.user_form(@current_user)}
          />
          <%!-- {error_tag(f, :password)} --%>

          <%!-- {label(f, :password_confirmation, "Confirm new password",
            class: StyleHelpers.user_form_label(@current_user)
          )} --%>
          <.input
            type="password"
            field={f[:password_confirmation]}
            required
            class={StyleHelpers.user_form(@current_user)}
          />
          <%!-- {error_tag(f, :password_confirmation)} --%>

          <%!-- {label(f, :current_password,
            for: "current_password_for_password",
            class: StyleHelpers.user_form_label(@current_user)
          )} --%>
          <.input
            type="password"
            field={f[:current_password]}
            required
            id="current_password_for_password"
            class={StyleHelpers.user_form(@current_user)}
          />
          <%!-- {error_tag(f, :current_password)} --%>

          <.button type="submit" phx-disable-with="Changing..." class={button_style(@current_user)}>
            Change password
          </.button>
        </.form>
      </div>
    </div>
    """
  end

  ## Tailwind Styles

  def confirmation_reminder_style(user) do
    ["md:mx-8 px-4 py-6 shadow rounded-lg ", confirmation_reminder_theme(user)]
  end

  def confirmation_reminder_theme(%{theme: "elixir"}), do: "bg-purple-200"
  def confirmation_reminder_theme(%{theme: "dark"}), do: "bg-purple-900 text-gray-200"

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
