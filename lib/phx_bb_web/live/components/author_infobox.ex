defmodule PhxBbWeb.AuthorInfobox do
  @moduledoc """
  Author infobox for each post.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBbWeb.{Endpoint, ForumLive, StyleHelpers, Timestamps}

  def link_to_profile(%{author: author, id: id}, active_user) do
    live_patch(author.username,
      to: Routes.live_path(Endpoint, ForumLive, user: author.id),
      class: StyleHelpers.link_style(active_user),
      phx_hook: "ScrollToTop",
      id: "post-#{id}-author-profile-link"
    )
  end

  def show_avatar(%{author: author, id: id}) do
    img_tag(author.avatar,
      class: [
        "max-h-40 object-fill mr-4 h-10 w-10 border border-gray-700 rounded-xl ",
        "md:h-auto md:w-32 md:mx-auto md:pt-2 md:border-none md:rounded-none"
      ],
      id: "post-#{id}-author-avatar"
    )
  end

  def post_author_style(user) do
    [
      "flex justify-end items-center flex-row-reverse pl-4 pb-2 pt-2 ",
      "md:pl-0 md:w-2/12 md:pt-4 md:text-center md:border-none md:block ",
      author_dividers(user)
    ]
  end

  def author_dividers(nil), do: author_dividers(%User{theme: StyleHelpers.default()})
  def author_dividers(%User{theme: "elixir"}), do: "border-b"
  def author_dividers(%User{theme: "dark"}), do: "border-b border-gray-500"
end
