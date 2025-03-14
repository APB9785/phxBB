defmodule PhxBbWeb.PostContent do
  @moduledoc """
  The content box for a post
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBb.Posts
  alias PhxBbWeb.{StyleHelpers, Timestamps}

  def mount(socket) do
    {:ok, assign(socket, edit: false)}
  end

  def update(%{active_post: active_post, current_user: current_user}, socket) do
    changeset = Posts.change_post(active_post)

    {:ok,
     assign(socket, changeset: changeset, active_post: active_post, current_user: current_user)}
  end

  def handle_event("edit_post", _params, socket) do
    {:noreply, assign(socket, edit: true)}
  end

  def handle_event("save_edit", %{"post" => params}, socket) do
    params = %{edited_by_id: socket.assigns.current_user.id, body: params["body"]}

    case Posts.update_post(socket.assigns.active_post, params) do
      {:ok, _post} ->
        {:noreply, assign(socket, edit: false)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"post" => params}, socket) do
    changeset =
      socket.assigns.active_post
      |> Posts.change_post(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("cancel_edit", _params, socket) do
    changeset = Posts.change_post(socket.assigns.active_post)

    {:noreply, assign(socket, edit: false, changeset: changeset)}
  end

  def handle_event("delete_post", %{"id" => _post_id}, socket) do
    params = %{body: "_Post deleted._", edited_by_id: socket.assigns.current_user.id}
    {:ok, _post} = Posts.update_post(socket.assigns.active_post, params)

    {:noreply, socket}
  end

  # Helpers

  def edit_post_form_value(changeset) do
    case changeset.changes[:body] do
      nil -> if changeset.errors == [], do: changeset.data.body, else: ""
      changed_body -> changed_body
    end
  end

  def may_edit?(user, post) do
    cond do
      admin?(user) -> true
      author?(user, post) and !disabled?(user) -> true
      true -> false
    end
  end

  def admin?(nil), do: false
  def admin?(%User{} = user), do: user.admin

  def author?(nil, _), do: false
  def author?(%User{} = user, post), do: user.id == post.author_id

  def disabled?(nil), do: false
  def disabled?(%User{disabled_at: time}), do: !is_nil(time)

  ## Tailwind Styles

  def post_timestamp_style(user), do: ["text-sm ", StyleHelpers.timestamp_theme(user)]

  def post_edit_link_style(user),
    do: ["text-sm hover:underline ", StyleHelpers.timestamp_theme(user)]

  def post_form_style(user) do
    [
      "appearance-none w-10/12 md:w-5/12 h-32 py-2 px-2 m-2 justify-self-center ",
      "rounded-md shadow-md transition duration-150 text-sm focus:outline-none focus:ring ",
      StyleHelpers.post_form_theme(user)
    ]
  end

  def small_button_style(user),
    do: ["rounded-md text-sm px-2 mx-2 ", StyleHelpers.button_theme(user)]
end
