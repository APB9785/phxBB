defmodule PhxBbWeb.PostComponent do
  @moduledoc """
  View a post and its replies.
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Replies
end
