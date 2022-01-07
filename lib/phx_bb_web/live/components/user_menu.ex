defmodule PhxBbWeb.UserMenu do
  @moduledoc """
  User menu displays username if logged in, along with links to login/logout
  and user settings.
  """

  use PhxBbWeb, :live_component

  alias Phoenix.HTML.Link
  alias PhxBbWeb.{Endpoint, ForumLive, StyleHelpers}

  def register_link do
    live_patch("Register",
      to: Routes.live_path(Endpoint, ForumLive, register: 1),
      id: "user-menu-register",
      class: StyleHelpers.link_style(nil)
    )
  end

  def login_link do
    Link.link("Log in",
      id: "user-menu-login",
      to: Routes.user_session_path(Endpoint, :new),
      class: StyleHelpers.link_style(nil)
    )
  end

  def user_profile_link(user) do
    live_patch(user.username,
      id: "user-menu-profile",
      to: Routes.live_path(Endpoint, ForumLive, user: user.id),
      class: StyleHelpers.link_style(user)
    )
  end

  def admin_panel_link(user) do
    live_patch("Admin Panel",
      to: Routes.live_path(Endpoint, ForumLive, admin: 1),
      id: "user-menu-admin",
      class: StyleHelpers.link_style(user)
    )
  end

  def settings_link(user) do
    live_patch("Settings",
      to: Routes.live_path(Endpoint, ForumLive, settings: 1),
      id: "user-menu-settings",
      class: StyleHelpers.link_style(user)
    )
  end

  def logout_link(user) do
    Link.link("Log out",
      id: "user-menu-logout",
      to: Routes.user_session_path(Endpoint, :delete),
      method: :delete,
      class: StyleHelpers.link_style(user)
    )
  end

  def messages_link(user) do
    live_patch("Messages",
      to: Routes.live_path(Endpoint, ForumLive, messages: "inbox"),
      id: "user-menu-messages",
      class: StyleHelpers.link_style(user)
    )
  end

  ## Tailwind styles

  def user_menu(user) do
    [
      "py-2 max-w-sm mx-auto rounded-lg md:rounded-md shadow-md antialiased ",
      "relative opacity-100 font-sans ",
      StyleHelpers.content_bg_theme(user)
    ]
  end
end
