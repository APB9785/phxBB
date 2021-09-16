defmodule PhxBbWeb.Topic do
  @moduledoc """
  View a Topic and its posts.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBbWeb.StyleHelpers

  def topic_content_style(user) do
    [
      "block rounded-xl mb-4 md:flex md:rounded-none md:bg-transparent ",
      StyleHelpers.content_bg_theme(user)
    ]
  end

  def post_dividers(nil), do: post_dividers(%User{theme: StyleHelpers.default()})
  def post_dividers(%User{theme: "elixir"}), do: "md:border-t-2 md:border-b-2 md:divide-y-2"

  def post_dividers(%User{theme: "dark"}) do
    "md:border-t-2 md:border-b-2 md:divide-y-2 md:border-gray-500 md:divide-gray-500"
  end
end
