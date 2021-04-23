defmodule PhxBbWeb.UserMenuComponent do
  @moduledoc """
  User menu displays username if logged in, along with links to login/logout
  and user settings.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.StyleHelpers
end
