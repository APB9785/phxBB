defmodule PhxBbWeb.CreateTopic do
  @moduledoc """
  New topic form.
  """

  use PhxBbWeb, :live_component

  alias PhxBb.Accounts.User
  alias PhxBb.Topics
  alias PhxBb.Topics.NewTopic
  alias PhxBbWeb.{ForumLive, StyleHelpers}

  def mount(socket) do
    {:ok, assign(socket, changeset: Topics.new_topic_changeset(%NewTopic{}))}
  end

  def handle_event("new_topic", _, %{assigns: %{active_user: %User{disabled_at: d}}} = socket)
      when not is_nil(d) do
    {:noreply, socket}
  end

  def handle_event("new_topic", %{"new_topic" => params}, socket) do
    u_id = socket.assigns.active_user.id
    b_id = socket.assigns.active_board.id

    attrs = %{
      body: params["body"],
      title: params["title"],
      board_id: b_id,
      author_id: u_id,
      recent_user_id: u_id
    }

    case Topics.create_topic(attrs) do
      {:ok, _topic} ->
        {:noreply, push_patch(socket, to: Routes.live_path(socket, ForumLive, board: b_id))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"new_topic" => params}, socket) do
    changeset =
      %NewTopic{}
      |> Topics.new_topic_changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  ## Tailwind Styles

  def topic_title_form_style(user) do
    ["mb-4 ", new_topic_form_base(), StyleHelpers.post_form_theme(user)]
  end

  def topic_body_form_style(user) do
    ["h-64 ", new_topic_form_base(), StyleHelpers.post_form_theme(user)]
  end

  defp new_topic_form_base do
    [
      "py-2 px-2 w-11/12 rounded-md transition shadow-md duration-150 text-sm ",
      "border border-black focus:outline-none focus:ring md:w-7/12 "
    ]
  end

  def button_style(user) do
    [
      "text-sm md:text-base px-4 md:px-8 py-2 mt-4 mb-4 rounded-md ",
      StyleHelpers.button_theme(user)
    ]
  end
end
