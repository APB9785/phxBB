defmodule PhxBbWeb.StyleHelpers do
  @moduledoc """
  This module contains helper functions for TailwindCSS styling.
  """

  alias PhxBb.Accounts.User

  def get_theme_background(user) do
    bg_color_map()
    |> Map.fetch!(user.theme)
  end

  def bg_color_map do
    %{
      "default" => "#C4B5FD",
      "dark" => "#374151"
    }
  end

  def settings_block(%User{theme: "default"}) do
    "md:mx-8 px-4 bg-white py-8 mb-6 shadow rounded-lg"
  end
  def settings_block(%User{theme: "dark"}) do
    "md:mx-8 px-4 bg-gray-200 py-8 mb-6 shadow rounded-lg"
  end

  def user_form(nil) do
    Enum.join([
      "mb-4 appearance-none w-full border-purple-300 rounded-md transition",
      "duration-150 text-sm focus:outline-none focus:ring",
      "focus:ring-purple-300 focus:border-purple-300"],
      " ")
  end
  def user_form(%User{theme: "default"}) do
    Enum.join([
      "mb-4 appearance-none w-full border-purple-300 rounded-md transition",
      "duration-150 text-sm focus:outline-none focus:ring",
      "focus:ring-purple-300 focus:border-purple-300"],
      " ")
  end
  def user_form(%User{theme: "dark"}) do
    Enum.join([
      "mb-4 appearance-none w-full border-gray-600 rounded-md transition",
      "duration-150 text-sm focus:outline-none focus:ring",
      "focus:ring-gray-500 focus:border-gray-900"],
      " ")
  end

  def user_form_label(nil), do: "block my-2 text-sm font-medium text-gray-600"
  def user_form_label(%User{theme: "default"}) do
    "block my-2 text-sm font-medium text-gray-600"
  end
  def user_form_label(%User{theme: "dark"}) do
    "block my-2 text-sm font-medium text-gray-800"
  end

  def reply_form_style(%User{theme: "default"}) do
    Enum.join([
      "appearance-none w-10/12 md:w-5/12 h-32 py-2 m-2 bg-white",
      "justify-self-center rounded-md shadow-md md:border-purple-300",
      "transition duration-150 text-sm focus:outline-none focus:ring",
      "focus:border-purple-700 focus:ring-purple-400 md:focus:ring-purple-300"],
      " ")
  end
  def reply_form_style(%User{theme: "dark"}) do
    Enum.join([
      "appearance-none w-10/12 md:w-5/12 h-32 py-2 m-2 bg-gray-100",
      "justify-self-center rounded-md shadow-md md:border-gray-900",
      "transition duration-150 text-sm focus:outline-none focus:ring",
      "focus:border-gray-900 focus:ring-gray-600 md:focus:ring-gray-600"],
      " ")
  end

  def topic_title_form_style(%User{theme: "default"}) do
    "py-2 mb-4 w-11/12 md:w-7/12 bg-white shadow-md rounded-md transition " <>
      "duration-150 text-sm focus:outline-none focus:ring focus:ring-purple-400" <>
      " focus:border-purple-700 md:focus:ring-purple-300 md:border-purple-400"
  end
  def topic_title_form_style(%User{theme: "dark"}) do
    "py-2 mb-4 w-11/12 md:w-7/12 bg-white shadow-md rounded-md transition " <>
      "duration-150 text-sm focus:outline-none focus:ring focus:ring-gray-600" <>
      " focus:border-gray-900 md:focus:ring-gray-600 md:border-gray-900"
  end

  def topic_body_form_style(%User{theme: "default"}) do
    "py-2 w-11/12 md:w-7/12 h-64 bg-white shadow-md rounded-md transition " <>
      "duration-150 text-sm focus:outline-none focus:ring focus:ring-purple-400" <>
      " focus:border-purple-700 md:focus:ring-purple-300 md:border-purple-400"
  end
  def topic_body_form_style(%User{theme: "dark"}) do
    "py-2 w-11/12 md:w-7/12 h-64 bg-white shadow-md rounded-md transition " <>
      "duration-150 text-sm focus:outline-none focus:ring focus:ring-gray-600" <>
      " focus:border-gray-900 md:focus:ring-gray-600 md:border-gray-900"
  end

  def user_menu(nil) do
    "py-2 max-w-sm mx-auto rounded-xl shadow-md antialiased relative opacity-100 font-sans bg-gray-100"
  end
  def user_menu(%User{theme: "default"}) do
    "py-2 max-w-sm mx-auto rounded-xl shadow-md antialiased relative opacity-100 font-sans bg-gray-100"
  end
  def user_menu(%User{theme: "dark"}) do
    "py-2 max-w-sm mx-auto rounded-xl shadow-md antialiased relative opacity-100 font-sans bg-gray-400"
  end

  def content_background(nil) do
    "mx-auto w-11/12 bg-transparent rounded-xl space-y-2 m-4 pb-4 antialiased relative font-sans" <>
      " max-w-full md:bg-gray-100 md:shadow-md"
  end
  def content_background(%User{theme: "default"}) do
    "mx-auto w-11/12 bg-transparent rounded-xl space-y-2 m-4 pb-4 antialiased relative font-sans" <>
      " max-w-full md:bg-gray-100 md:shadow-md"
  end
  def content_background(%User{theme: "dark"}) do
    "mx-auto w-11/12 bg-transparent rounded-xl space-y-2 m-4 pb-4 antialiased relative font-sans" <>
      " max-w-full md:bg-gray-400 md:shadow-md"
  end

  def board_dividers(nil), do: "divide-y-2"
  def board_dividers(%User{theme: "default"}), do: "divide-y-2"
  def board_dividers(%User{theme: "dark"}), do: "divide-y-2 divide-gray-500"

  def post_dividers(nil), do: "md:border-t-2 md:border-b-2 md:divide-y-2"
  def post_dividers(%User{theme: "default"}), do: "md:border-t-2 md:border-b-2 md:divide-y-2"
  def post_dividers(%User{theme: "dark"}) do
    "md:border-t-2 md:border-b-2 md:divide-y-2 md:border-gray-500"
  end

  def button_style(nil) do
    "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 w-6/12 md:w-3/12 rounded-md bg-purple-700 text-white"
  end
  def button_style(%User{theme: "default"}) do
    "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 w-6/12 md:w-3/12 rounded-md bg-purple-700 text-white"
  end
  def button_style(%User{theme: "dark"}) do
    "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 w-6/12 md:w-3/12 rounded-md bg-gray-900 text-white"
  end

  def new_post_button_style(nil), do: "px-8 py-2 justify-center rounded-md bg-purple-700 text-white"
  def new_post_button_style(%User{theme: "default"}) do
    "px-8 py-2 justify-center rounded-md bg-purple-700 text-white"
  end
  def new_post_button_style(%User{theme: "dark"}) do
    "px-8 py-2 justify-center rounded-md bg-gray-900 text-gray-100"
  end

  def reply_button_style(nil) do
    "px-8 py-2 m-2 rounded-md justify-self-center bg-purple-700 md:w-1/6 text-white"
  end
  def reply_button_style(%User{theme: "default"}) do
    "px-8 py-2 m-2 rounded-md justify-self-center bg-purple-700 md:w-1/6 text-white"
  end
  def reply_button_style(%User{theme: "dark"}) do
    "px-8 py-2 m-2 rounded-md justify-self-center bg-gray-900 md:w-1/6 text-gray-100"
  end

  def link_style, do: "text-purple-700 hover:underline"

  def link_style(nil), do: "text-purple-700 hover:underline"
  def link_style(%User{theme: "default"}), do: "text-purple-700 hover:underline"
  def link_style(%User{theme: "dark"}), do: "text-gray-900 hover:underline font-bold"

  def board_title_style(nil), do: "text-purple-700 hover:underline font-bold text-lg"
  def board_title_style(%User{theme: "default"}) do
    "text-purple-700 hover:underline font-bold text-lg"
  end
  def board_title_style(%User{theme: "dark"}) do
    "text-gray-900 hover:underline font-bold text-lg"
  end

  def main_header_style(nil), do: "text-3xl text-purple-700 text-center p-4"
  def main_header_style(%User{theme: "default"}), do: "text-3xl text-purple-700 text-center p-4"
  def main_header_style(%User{theme: "dark"}), do: "text-3xl text-gray-900 text-center p-4"
end
