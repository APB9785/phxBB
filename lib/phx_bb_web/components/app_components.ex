defmodule PhxBbWeb.AppComponents do

  attr :current_user, :map
  attr :post, :map

  def author_infobox(assigns) do
    ~H"""
    <div class={post_author_style(@current_user)}>
  <div>
    <.link patch={~p"/forum/user/#{@post.author.id}"}
      class={StyleHelpers.link_style(@current_user)}
      phx_hook="ScrollToTop"
      id={"post-#{id}-author-profile-link"}
    >{@post.author.username}</.link>

    <div id={"post-#{@post.id}-author-title"} class="text-sm">
      {@post.author.title}
    </div>
  </div>

  <img
  :if={@post.author.avatar}
  src={@post.author.avatar}
      class={[
        "max-h-40 object-fill mr-4 h-10 w-10 border border-gray-700 rounded-xl",
        "md:h-auto md:w-32 md:mx-auto md:pt-2 md:border-none md:rounded-none"
      ]}
      id={"post-#{@post.id}-author-avatar"}
    />

<!-- This block hidden on devices with small screens -->
  <div class="hidden md:block">
    <p id={"post-#{@post.id}-author-post-count"} class="text-sm mt-4">
      Posts: {@post.author.post_count}
    </p>

    <p id={"post-#{@post.id}-author-join-date"} class="text-sm">
      Joined: {Timestamps.format_date(@post.author.inserted_at, @current_user)}
    </p>
  </div>
</div>
    """
  end

  defp post_author_style(user) do
    [
      "flex justify-end items-center flex-row-reverse pl-4 pb-2 pt-2 ",
      "md:pl-0 md:w-2/12 md:pt-4 md:text-center md:border-none md:block ",
      author_dividers(user)
    ]
  end

  defp author_dividers(nil), do: author_dividers(%User{theme: StyleHelpers.default()})
  defp author_dividers(%User{theme: "elixir"}), do: "border-b"
  defp author_dividers(%User{theme: "dark"}), do: "border-b border-gray-500"
end
