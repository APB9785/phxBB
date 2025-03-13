defmodule PhxBbWeb.CreateTopic do
  @moduledoc """
  New topic form.
  """
  use PhxBbWeb, :live_view

  alias PhxBb.Topics
  alias PhxBb.Topics.NewTopic
  alias PhxBbWeb.StyleHelpers

  def mount(socket) do
    {:ok, assign(socket, changeset: Topics.new_topic_changeset(%NewTopic{}))}
  end

  def handle_event("new_topic", _, %{assigns: %{current_user: %{disabled_at: d}}} = socket)
      when not is_nil(d) do
    {:noreply, socket}
  end

  def handle_event("new_topic", %{"new_topic" => params}, socket) do
    u_id = socket.assigns.current_user.id
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

  def render(assigns) do
    ~H"""
    <div class="flex w-full md:ml-8">
      <.form
        let={f}
        for={@changeset}
        id="new-topic-form"
        class="grid w-full"
        phx_submit="new_topic"
        phx_change="validate"
      >
        {text_input(f, :title,
          placeholder: "Subject",
          phx_debounce: "blur",
          autocomplete: "off",
          class: topic_title_form_style(@current_user)
        )}
        <div class="pl-6 pt-4">
          {error_tag(f, :title)}
        </div>

        {textarea(f, :body,
          placeholder: "You may user Markdown to format your post",
          phx_debounce: "blur",
          autocomplete: "off",
          class: topic_body_form_style(@current_user)
        )}
        <div class="pl-6 pt-4">
          {error_tag(f, :body)}
        </div>

        <%= if @current_user.disabled_at do %>
          <p>Your posting privileges have been revoked by the forum administrator.</p>
        <% else %>
          <div>
            {submit("Create Post",
              phx_disable_with: "Posting...",
              class: button_style(@current_user)
            )}
          </div>
        <% end %>
      </.form>
    </div>
    """
  end

  ## Tailwind Styles

  def topic_title_form_style(user) do
    [new_topic_form_base(), StyleHelpers.post_form_theme(user)]
  end

  def topic_body_form_style(user) do
    ["h-64 mt-4 ", new_topic_form_base(), StyleHelpers.post_form_theme(user)]
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
