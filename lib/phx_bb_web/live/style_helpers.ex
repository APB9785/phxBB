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

  def timestamp_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "text-gray-500",
      "dark" => "text-gray-800"
    }
    |> Map.fetch!(theme)
  end

  def post_timestamp_style(user) do
    ["text-sm", timestamp_theme(user)]
    |> Enum.join(" ")
  end

  def user_history_timestamp_style(user) do
    ["text-sm w-40 pb-2", timestamp_theme(user)]
    |> Enum.join(" ")
  end

  # User form fields

  def user_form(user) do
    [user_form_base(), user_form_theme(user)]
    |> Enum.join(" ")
  end

  defp user_form_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "border-purple-300 focus:ring-purple-300 focus:border-purple-300",
      "dark" => "border-gray-600 focus:ring-gray-500 focus:border-gray-900"
    }
    |> Map.fetch!(theme)
  end

  defp user_form_base do
    "mb-4 appearance-none w-full rounded-md transition duration-150 text-sm focus:outline-none focus:ring"
  end

  # User form labels

  def user_form_label(user) do
    ["block my-2 text-sm font-medium", form_label_theme(user)]
    |> Enum.join(" ")
  end

  defp form_label_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "text-gray-600",
      "dark" => "text-gray-800"
    }
    |> Map.fetch!(theme)
  end

  # New Topic + Reply form

  def topic_title_form_style(user) do
    ["mb-4", new_topic_form_base(), post_form_theme(user)]
    |> Enum.join(" ")
  end

  def topic_body_form_style(user) do
    ["h-64", new_topic_form_base(), post_form_theme(user)]
    |> Enum.join(" ")
  end

  defp new_topic_form_base do
    ["py-2 w-11/12 rounded-md transition shadow-md duration-150 text-sm",
      "focus:outline-none focus:ring md:w-7/12"]
    |> Enum.join(" ")
  end

  def reply_form_style(user) do
    [reply_form_base(), post_form_theme(user)]
    |> Enum.join(" ")
  end

  defp reply_form_base do
    ["appearance-none w-10/12 md:w-5/12 h-32 py-2 m-2 justify-self-center",
      "rounded-md shadow-md transition duration-150 text-sm focus:outline-none focus:ring"]
    |> Enum.join(" ")
  end

  defp post_form_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    all_size =
      %{"default" => "bg-white focus:border-purple-700 focus:ring-purple-400",
        "dark" => "bg-gray-200 focus:border-gray-900 focus:ring-gray-600"}
    desktop_size =
      %{"default" => "md:focus:ring-purple-300 md:border-purple-400",
        "dark" => "md:focus:ring-gray-600 md:border-gray-700"}

    [all_size, desktop_size]
    |> Enum.map(&Map.fetch!(&1, theme))
    |> Enum.join(" ")
  end

  # User menu

  def user_menu(user) do
    [user_menu_base(), user_menu_theme(user)]
    |> Enum.join(" ")
  end

  defp user_menu_base do
    "py-2 max-w-sm mx-auto rounded-xl shadow-md antialiased relative opacity-100 font-sans"
  end

  defp user_menu_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "bg-gray-100",
      "dark" => "bg-gray-400"
    }
    |> Map.fetch!(theme)
  end

  # Content background

  def content_background(user) do
    [content_bg_base(), content_bg_theme(user)]
    |> Enum.join(" ")
  end

  defp content_bg_base do
    ["mx-auto w-11/12 bg-transparent rounded-xl space-y-2 m-4 pb-4",
      "antialiased relative font-sans max-w-full md:shadow-md"]
    |> Enum.join(" ")
  end

  defp content_bg_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "md:bg-gray-100",
      "dark" => "md:bg-gray-400"
    }
    |> Map.fetch!(theme)
  end

  # Dividers

  def board_dividers(nil), do: "divide-y-2"
  def board_dividers(%User{theme: "default"}), do: "divide-y-2"
  def board_dividers(%User{theme: "dark"}), do: "divide-y-2 divide-gray-500"

  def post_dividers(nil), do: "md:border-t-2 md:border-b-2 md:divide-y-2"
  def post_dividers(%User{theme: "default"}), do: "md:border-t-2 md:border-b-2 md:divide-y-2"
  def post_dividers(%User{theme: "dark"}) do
    "md:border-t-2 md:border-b-2 md:divide-y-2 md:border-gray-500 md:divide-gray-500"
  end

  # Buttons

  def button_style(user) do
    [button_base(), button_theme(user)]
    |> Enum.join(" ")
  end

  defp button_base do
    "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 w-6/12 md:w-3/12 rounded-md"
  end

  def new_post_button_style(user) do
    [new_post_button_base(), button_theme(user)]
    |> Enum.join(" ")
  end

  defp new_post_button_base do
    "px-8 py-2 justify-center rounded-md"
  end

  def reply_button_style(user) do
    [reply_button_base(), button_theme(user)]
    |> Enum.join(" ")
  end

  defp reply_button_base do
    "px-8 py-2 m-2 rounded-md justify-self-center md:w-1/6"
  end

  defp button_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "bg-purple-700 text-white",
      "dark" => "bg-gray-900 text-gray-100"
    }
    |> Map.fetch!(theme)
  end

  # Links

  def link_style(nil), do: "text-purple-700 hover:underline"
  def link_style(%User{theme: "default"}), do: "text-purple-700 hover:underline"
  def link_style(%User{theme: "dark"}), do: "text-gray-900 hover:underline font-bold"

  # Text

  def text_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "text-purple-700",
      "dark" => "text-gray-900"
    }
    |> Map.fetch!(theme)
  end

  def board_title_style(user) do
    [board_title_base(), text_theme(user)]
    |> Enum.join(" ")
  end

  def board_title_base do
    "hover:underline font-bold text-lg"
  end

  def main_header_style(user) do
    [main_header_base(), text_theme(user)]
    |> Enum.join(" ")
  end

  def main_header_base do
    "text-3xl text-center p-4"
  end

  # Content Bubbles

  def user_history_bubble_style(user) do
    [user_history_bubble_base(), content_bubble_theme(user)]
    |> Enum.join(" ")
  end

  defp user_history_bubble_base do
    "p-2 pb-4 pr-4 w-min rounded-xl shadow-md md:ml-8"
  end

  def settings_block(user) do
    [settings_block_base(), content_bubble_theme(user)]
    |> Enum.join(" ")
  end

  defp settings_block_base do
    "px-4 py-8 mb-6 shadow rounded-lg md:mx-8"
  end

  defp content_bubble_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "bg-white",
      "dark" => "bg-gray-300"
    }
    |> Map.fetch!(theme)
  end

  def confirmation_reminder_style(user) do
    ["md:mx-8 px-4 py-6 shadow rounded-lg", confirmation_reminder_theme(user)]
    |> Enum.join(" ")
  end

  defp confirmation_reminder_theme(user) do
    theme = if is_nil(user) do "default" else user.theme end
    %{
      "default" => "bg-purple-200",
      "dark" => "bg-purple-900 text-gray-300"
    }
    |> Map.fetch!(theme)
  end
end
