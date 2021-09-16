defmodule PhxBbWeb.StyleHelpers do
  @moduledoc """
  This module contains helper functions for TailwindCSS styling.
  """

  alias PhxBb.Accounts.User

  @bg_color_map %{
    "elixir" => "#C4B5FD",
    "dark" => "#374151"
  }

  @default "dark"

  def default, do: @default

  def get_theme_background(%User{} = user), do: Map.fetch!(@bg_color_map, user.theme)

  def get_default_background, do: Map.fetch!(@bg_color_map, @default)

  def theme_list, do: Map.keys(@bg_color_map)

  # Links

  def link_style(nil), do: link_style(%User{theme: @default})
  def link_style(%User{theme: "elixir"}), do: "text-purple-700 hover:underline"
  def link_style(%User{theme: "dark"}), do: "text-gray-900 hover:underline font-bold"

  # Text

  def text_theme(nil), do: text_theme(%User{theme: @default})
  def text_theme(%User{theme: "elixir"}), do: "text-purple-700"
  def text_theme(%User{theme: "dark"}), do: "text-gray-900"

  # Timestamps

  def timestamp_theme(nil), do: timestamp_theme(%User{theme: @default})
  def timestamp_theme(%User{theme: "elixir"}), do: "text-gray-500"
  def timestamp_theme(%User{theme: "dark"}), do: "text-gray-800"

  # Buttons

  def button_theme(nil), do: button_theme(%User{theme: @default})
  def button_theme(%User{theme: "elixir"}), do: "bg-purple-700 text-white"
  def button_theme(%User{theme: "dark"}), do: "bg-gray-900 text-gray-100"

  # Forms

  def user_form_label(user), do: ["block my-2 text-sm font-medium ", form_label_theme(user)]

  defp form_label_theme(nil), do: form_label_theme(%User{theme: @default})
  defp form_label_theme(%User{theme: "elixir"}), do: "text-gray-600"
  defp form_label_theme(%User{theme: "dark"}), do: "text-gray-800"

  def user_form(user) do
    [
      "mb-4 w-full rounded-md transition duration-150 text-sm ",
      "px-2 py-1 border border-black focus:outline-none focus:ring ",
      user_form_theme(user)
    ]
  end

  defp user_form_theme(nil), do: user_form_theme(%User{theme: @default})

  defp user_form_theme(%User{theme: theme}) do
    case theme do
      "elixir" -> "border-purple-300 focus:ring-purple-300 focus:border-purple-300"
      "dark" -> "border-gray-600 focus:ring-gray-500 focus:border-gray-900"
    end
  end

  def post_form_theme(%User{theme: theme}) do
    case theme do
      "elixir" ->
        [
          "bg-white focus:border-purple-700 focus:ring-purple-400 ",
          "md:focus:ring-purple-300 md:border-purple-400"
        ]

      "dark" ->
        [
          "bg-gray-200 focus:border-gray-900 focus:ring-gray-600 ",
          "md:focus:ring-gray-600 md:border-gray-700"
        ]
    end
  end

  # Content background

  def content_background(user),
    do: [content_bg_base(), " ", content_bg_theme_md_only(user)]

  defp content_bg_base do
    [
      "mx-auto w-11/12 bg-transparent rounded-md space-y-2 m-4 pb-4 ",
      "antialiased relative font-sans max-w-full md:shadow-md"
    ]
  end

  def content_bg_theme(nil), do: content_bg_theme(%User{theme: @default})
  def content_bg_theme(%User{theme: "elixir"}), do: "bg-gray-100"
  def content_bg_theme(%User{theme: "dark"}), do: "bg-gray-400"

  def content_bg_theme_md_only(nil), do: content_bg_theme_md_only(%User{theme: @default})
  def content_bg_theme_md_only(%User{theme: "elixir"}), do: "md:bg-gray-100"
  def content_bg_theme_md_only(%User{theme: "dark"}), do: "md:bg-gray-400"

  # These bubbles are used in User Profiles, Settings menu, and Admin Panel
  def content_bubble_theme(nil), do: content_bubble_theme(%User{theme: @default})
  def content_bubble_theme(%User{theme: "elixir"}), do: "bg-white"
  def content_bubble_theme(%User{theme: "dark"}), do: "bg-gray-300"
end
