defmodule PhxBbWeb.StyleHelpers do
  @moduledoc """
  This module contains helper functions for TailwindCSS styling.
  """

  alias PhxBb.Accounts.User

  @bg_color_map %{
    "default" => "#C4B5FD",
    "dark" => "#374151"
  }

  def get_theme_background(user), do: Map.fetch!(@bg_color_map, user.theme)

  def get_default_background, do: Map.fetch!(@bg_color_map, "default")

  def theme_list, do: Map.keys(@bg_color_map)

  # Post timestamp headers

  def timestamp_theme(nil), do: timestamp_theme(%User{theme: "default"})
  def timestamp_theme(%User{theme: "default"}), do: "text-gray-500"
  def timestamp_theme(%User{theme: "dark"}), do: "text-gray-800"

  def post_timestamp_style(user), do: "text-sm #{timestamp_theme(user)}"

  def post_edit_link_style(user), do: "text-sm hover:underline #{timestamp_theme(user)}"

  def user_history_timestamp_style(user), do: "text-sm w-40 pb-2 #{timestamp_theme(user)}"

  def post_content_style(user) do
    "block rounded-xl mb-4 md:flex md:rounded-none md:bg-transparent #{content_bg_theme(user)}"
  end

  # User form fields

  def user_form(user), do: "#{user_form_base()} #{user_form_theme(user)}"

  defp user_form_theme(nil), do: user_form_theme(%User{theme: "default"})

  defp user_form_theme(%User{theme: theme}) do
    case theme do
      "default" -> "border-purple-300 focus:ring-purple-300 focus:border-purple-300"
      "dark" -> "border-gray-600 focus:ring-gray-500 focus:border-gray-900"
    end
  end

  defp user_form_base do
    "mb-4 appearance-none w-full rounded-md transition duration-150 text-sm focus:outline-none focus:ring"
  end

  # User form labels

  def user_form_label(user), do: "block my-2 text-sm font-medium #{form_label_theme(user)}"

  defp form_label_theme(nil), do: form_label_theme(%User{theme: "default"})
  defp form_label_theme(%User{theme: "default"}), do: "text-gray-600"
  defp form_label_theme(%User{theme: "dark"}), do: "text-gray-800"

  # New Topic + Reply form

  def topic_title_form_style(user) do
    "mb-4 #{new_topic_form_base()} #{post_form_theme(user)}"
  end

  def topic_body_form_style(user) do
    "h-64 #{new_topic_form_base()} #{post_form_theme(user)}"
  end

  defp new_topic_form_base do
    "py-2 w-11/12 rounded-md transition shadow-md duration-150 text-sm" <>
      "focus:outline-none focus:ring md:w-7/12"
  end

  def reply_form_style(user), do: "#{reply_form_base()} #{post_form_theme(user)}"

  defp reply_form_base do
    "appearance-none w-10/12 md:w-5/12 h-32 py-2 m-2 justify-self-center" <>
      "rounded-md shadow-md transition duration-150 text-sm focus:outline-none focus:ring"
  end

  defp post_form_theme(nil), do: post_form_theme(%User{theme: "default"})

  defp post_form_theme(%User{theme: theme}) do
    case theme do
      "default" ->
        "bg-white focus:border-purple-700 focus:ring-purple-400" <>
          "md:focus:ring-purple-300 md:border-purple-400"

      "dark" ->
        "bg-gray-200 focus:border-gray-900 focus:ring-gray-600" <>
          "md:focus:ring-gray-600 md:border-gray-700"
    end
  end

  # User menu

  def user_menu(user), do: "#{user_menu_base()} #{content_bg_theme(user)}"

  defp user_menu_base do
    "py-2 max-w-sm mx-auto rounded-lg md:rounded-md shadow-md antialiased relative opacity-100 font-sans"
  end

  # Content background

  def content_background(user), do: "#{content_bg_base()} #{content_bg_theme_md_only(user)}"

  defp content_bg_base do
    "mx-auto w-11/12 bg-transparent rounded-md space-y-2 m-4 pb-4" <>
      "antialiased relative font-sans max-w-full md:shadow-md"
  end

  # Dividers

  def board_dividers(nil), do: board_dividers(%User{theme: "default"})
  def board_dividers(%User{theme: "default"}), do: "md:divide-y-2"
  def board_dividers(%User{theme: "dark"}), do: "md:divide-y-2 md:divide-gray-500"

  def post_dividers(nil), do: post_dividers(%User{theme: "default"})
  def post_dividers(%User{theme: "default"}), do: "md:border-t-2 md:border-b-2 md:divide-y-2"

  def post_dividers(%User{theme: "dark"}) do
    "md:border-t-2 md:border-b-2 md:divide-y-2 md:border-gray-500 md:divide-gray-500"
  end

  def author_dividers(nil), do: author_dividers(%User{theme: "default"})
  def author_dividers(%User{theme: "default"}), do: "border-b"
  def author_dividers(%User{theme: "dark"}), do: "border-b border-gray-500"

  # Buttons

  def button_style(user), do: "#{button_base()} #{button_theme(user)}"

  defp button_base, do: "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 rounded-md"

  def new_post_button_style(user), do: "#{new_post_button_base()} #{button_theme(user)}"

  defp new_post_button_base, do: "px-8 py-2 justify-center rounded-md text-sm"

  def reply_button_style(user), do: "#{reply_button_base()} #{button_theme(user)}"

  defp reply_button_base, do: "px-8 py-2 m-2 rounded-md justify-self-center"

  defp button_theme(nil), do: button_theme(%User{theme: "default"})
  defp button_theme(%User{theme: "default"}), do: "bg-purple-700 text-white"
  defp button_theme(%User{theme: "dark"}), do: "bg-gray-900 text-gray-100"

  def small_button_style(user), do: "rounded-md text-sm px-2 mx-2 #{button_theme(user)}"

  # Links

  def link_style(nil), do: link_style(%User{theme: "default"})
  def link_style(%User{theme: "default"}), do: "text-purple-700 hover:underline"
  def link_style(%User{theme: "dark"}), do: "text-gray-900 hover:underline font-bold"

  # Text

  def text_theme(nil), do: text_theme(%User{theme: "default"})
  def text_theme(%User{theme: "default"}), do: "text-purple-700"
  def text_theme(%User{theme: "dark"}), do: "text-gray-900"

  def board_title_style(user), do: "#{board_title_base()} #{text_theme(user)}"

  def board_title_base, do: "hover:underline font-bold text-lg"

  def main_header_style(user), do: "#{main_header_base()} #{text_theme(user)}"

  def main_header_base, do: "text-3xl text-center p-4"

  # Content Bubbles

  def post_author_style(user) do
    "flex justify-end items-center flex-row-reverse pl-4 pb-2 pt-2" <>
      "md:pl-0 md:w-2/12 md:pt-4 md:text-center md:border-none md:block" <>
      author_dividers(user)
  end

  def topic_bubble_style(user) do
    "p-4 block items-center rounded-lg m-1" <>
      "md:flex md:m-0 md:bg-transparent md:rounded-none" <>
      content_bg_theme(user)
  end

  def user_history_bubble_style(user) do
    "#{user_history_bubble_base()} #{content_bubble_theme(user)}"
  end

  defp user_history_bubble_base do
    "p-2 pb-4 pr-4 rounded-xl w-max max-w-full md:max-w-prose shadow-md md:mx-8"
  end

  def settings_block(user), do: "#{settings_block_base()} #{content_bubble_theme(user)}"

  defp settings_block_base, do: "px-4 py-8 mb-6 shadow rounded-lg md:mx-8"

  defp content_bubble_theme(nil), do: content_bubble_theme(%User{theme: "default"})
  defp content_bubble_theme(%User{theme: "default"}), do: "bg-white"
  defp content_bubble_theme(%User{theme: "dark"}), do: "bg-gray-300"

  def confirmation_reminder_style(user) do
    "md:mx-8 px-4 py-6 shadow rounded-lg #{confirmation_reminder_theme(user)}"
  end

  defp confirmation_reminder_theme(nil), do: confirmation_reminder_theme(%User{theme: "default"})
  defp confirmation_reminder_theme(%User{theme: "default"}), do: "bg-purple-200"
  defp confirmation_reminder_theme(%User{theme: "dark"}), do: "bg-purple-900 text-gray-300"

  # UsersOnlineComponent helpers

  def users_online_style(user), do: "#{users_online_base()} #{users_online_theme(user)}"

  defp users_online_base do
    "shadow-inner px-4 md:px-8 flex flex-wrap mx-1 md:mx-4 rounded-lg md:rounded-md py-4"
  end

  defp users_online_theme(nil), do: users_online_theme(%User{theme: "default"})
  defp users_online_theme(%User{theme: "default"}), do: "bg-purple-700"
  defp users_online_theme(%User{theme: "dark"}), do: "bg-gray-800"

  def online_user_bubble_style(user) do
    "#{online_user_bubble_base()} #{online_user_bubble_theme(user)}"
  end

  defp online_user_bubble_base do
    "px-1 mx-1 rounded-lg text-sm flex items-center shadow-inner"
  end

  defp online_user_bubble_theme(nil), do: online_user_bubble_theme(%User{theme: "default"})
  defp online_user_bubble_theme(%User{theme: "default"}), do: "bg-gray-200"
  defp online_user_bubble_theme(%User{theme: "dark"}), do: "bg-gray-300"

  def index_board_bubble_style(user) do
    "#{index_board_bubble_base()} #{index_board_bubble_theme(user)}"
  end

  defp index_board_bubble_base do
    "rounded-lg m-1 md:bg-transparent md:rounded-t-none md:flex md:m-0"
  end

  defp index_board_bubble_theme(nil), do: index_board_bubble_theme(%User{theme: "default"})
  defp index_board_bubble_theme(%User{theme: "default"}), do: "bg-gray-200"
  defp index_board_bubble_theme(%User{theme: "dark"}), do: "bg-gray-400"

  def board_stats_style(user), do: "#{board_stats_base()} #{board_stats_theme(user)}"

  defp board_stats_base do
    "pl-4 pt-2 text-sm border-t flex md:p-4 md:text-base md:grid md:border-0 md:w-1/12 md:content-evenly"
  end

  defp board_stats_theme(nil), do: board_stats_theme(%User{theme: "default"})
  defp board_stats_theme(%User{theme: "default"}), do: "border-gray-300"
  defp board_stats_theme(%User{theme: "dark"}), do: "border-gray-500"

  def avatar_style do
    "max-h-40 object-fill mr-4 h-10 w-10 border border-gray-700 rounded-xl" <>
      "md:h-auto md:w-32 md:mx-auto md:pt-2 md:border-none md:rounded-none"
  end

  # Theme-specific content

  defp content_bg_theme(nil), do: content_bg_theme(%User{theme: "default"})
  defp content_bg_theme(%User{theme: "default"}), do: "bg-gray-100"
  defp content_bg_theme(%User{theme: "dark"}), do: "bg-gray-400"

  defp content_bg_theme_md_only(nil), do: content_bg_theme_md_only(%User{theme: "default"})
  defp content_bg_theme_md_only(%User{theme: "default"}), do: "md:bg-gray-100"
  defp content_bg_theme_md_only(%User{theme: "dark"}), do: "md:bg-gray-400"
end
