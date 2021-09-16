defmodule PhxBbWeb.CreatePost do
  @moduledoc """
  New post form.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBb.Posts
  alias PhxBb.Posts.Post
  alias PhxBbWeb.StyleHelpers

  def mount(socket) do
    {:ok, assign(socket, changeset: Posts.change_post(%Post{}))}
  end

  def handle_event("new_post", _, %{assigns: %{active_user: %User{disabled_at: d}}} = socket)
      when not is_nil(d) do
    {:noreply, socket}
  end

  def handle_event("new_post", %{"post" => params}, socket) do
    u_id = socket.assigns.active_user.id
    t_id = socket.assigns.active_topic.id
    b_id = socket.assigns.active_topic.board_id
    attrs = %{body: params["body"], author_id: u_id, topic_id: t_id, board_id: b_id}

    case Posts.create_post(attrs) do
      {:ok, _post} ->
        {:noreply, assign(socket, changeset: Posts.change_post(%Post{}))}

      _ ->
        # Show validation error(s) only after failed submission
        changeset = Map.put(socket.assigns.changeset, :action, :insert)
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"post" => params}, socket) do
    changeset = Posts.change_post(%Post{}, params)
    # No live validation but still save the changeset
    {:noreply, assign(socket, changeset: changeset)}
  end

  ## Tailwind Styles

  def post_form_style(user) do
    [
      "appearance-none w-10/12 md:w-5/12 h-32 py-2 px-2 m-2 justify-self-center ",
      "rounded-md shadow-md transition duration-150 text-sm focus:outline-none focus:ring ",
      StyleHelpers.post_form_theme(user)
    ]
  end

  def new_post_button_style(user),
    do: ["px-8 py-2 m-2 rounded-md justify-self-center ", StyleHelpers.button_theme(user)]
end
