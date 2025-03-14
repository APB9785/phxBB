defmodule PhxBbWeb.Presence do
  @moduledoc """
  Tracks active users for display in `.users_online` component
  """

  use Phoenix.Presence,
    otp_app: :phx_bb,
    pubsub_server: PhxBb.PubSub
end
