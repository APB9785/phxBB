defmodule PhxBbWeb.Presence do
  @moduledoc """
  Tracks active users for display in PhxBbWeb.UsersOnline
  """

  use Phoenix.Presence,
    otp_app: :phx_bb,
    pubsub_server: PhxBb.PubSub
end
