defmodule PhxBbWeb.ForumLive do
  @moduledoc """
  This is the main LiveView which renders the forum.
  """
  use PhxBbWeb, :live_view

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBb.Boards
  alias PhxBb.Boards.Board
  alias PhxBb.Messages
  alias PhxBb.SeenTopics
  alias PhxBb.Topics
  alias PhxBb.Topics.Topic
  alias PhxBbWeb.{Endpoint, Presence, StyleHelpers}

  @presence "phx_bb:presence"

  def mount(_params, session, socket) do
    socket =
      case Accounts.get_user_by_session_token(session["user_token"]) do
        nil ->
          # User is logged out
          if connected?(socket) do
            Presence.track(self(), @presence, guest_id(), %{name: "guest"})
            Phoenix.PubSub.subscribe(PhxBb.PubSub, @presence)
          end

          socket
          |> assign(unread_messages: nil)
          |> assign(current_user: nil)
          |> assign(bg_color: StyleHelpers.get_default_background())
          |> assign_defaults()

        user ->
          # User is logged in
          if connected?(socket) do
            Presence.track(self(), @presence, user.id, %{name: user.username})
            Phoenix.PubSub.subscribe(PhxBb.PubSub, @presence)
            Phoenix.PubSub.subscribe(PhxBb.PubSub, "user:#{user.id}")
          end

          socket
          |> assign(unread_messages: Messages.unread_for_user(user.id))
          |> assign(current_user: user)
          |> assign(bg_color: StyleHelpers.get_theme_background(user))
          |> assign_defaults()
      end

    {:ok, socket, temporary_assigns: [post_list: []]}
  end

  def handle_params(%{"create_topic" => "1", "board" => _}, _url, socket)
      when is_nil(socket.assigns.current_user) do
    {:noreply, push_redirect(socket, to: "/users/log_in")}
  end

  def handle_params(%{"create_topic" => "1", "board" => board_id}, _url, socket) do
    case Boards.get_board(board_id) do
      nil ->
        {:noreply, assign_invalid(socket)}

      %Board{} = board ->
        {:noreply,
         assign(socket,
           nav: :create_topic,
           page_title: "Create Topic",
           active_board: board,
           child_pid: nil
         )}
    end
  end

  def handle_params(%{"topic" => topic_id}, _url, socket) do
    case Topics.get_topic(topic_id) do
      nil ->
        {:noreply, assign_invalid(socket)}

      %Topic{} = topic ->
        user = socket.assigns.current_user
        user_id = if user, do: user.id, else: nil
        SeenTopics.seen_now(user_id, topic.id)
        Topics.increment_view_count(topic.id)
        posts = PhxBb.Posts.list_posts(topic.id)

        {:noreply,
         socket
         |> resubscribe("topic:" <> topic_id)
         |> assign(
           nav: :topic,
           page_title: topic.title,
           active_topic: topic,
           post_list: posts,
           child_pid: nil
         )}
    end
  end

  def handle_params(%{"board" => board_id}, _url, socket) do
    case Boards.get_board(board_id) do
      nil ->
        {:noreply, assign_invalid(socket)}

      %Board{} = board ->
        {:noreply, assign(socket, nav: :board, page_title: board.name, active_board: board)}
    end
  end

  def handle_params(%{"user" => user_id}, _url, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        {:noreply, assign_invalid(socket)}

      user ->
        {:noreply,
         assign(socket,
           nav: :user_profile,
           page_title: user.username,
           view_user: user,
           child_pid: nil
         )}
    end
  end

  def handle_params(%{"settings" => "1"}, _url, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}

      _user ->
        {:noreply, assign(socket, nav: :settings, page_title: "User Settings", child_pid: nil)}
    end
  end

  def handle_params(%{"admin" => "1"}, _url, socket) do
    if is_admin?(socket.assigns.current_user) do
      {:noreply, assign(socket, nav: :admin, page_title: "Admin Panel", child_pid: nil)}
    else
      {:noreply, assign_invalid(socket)}
    end
  end

  def handle_params(%{"register" => "1"}, _url, socket) do
    if is_nil(socket.assigns.current_user) do
      {:noreply, assign(socket, nav: :register, page_title: "Register", child_pid: nil)}
    else
      {:noreply,
       socket
       |> put_flash(:info, "You are already registered and logged in.")
       |> push_patch(to: Routes.live_path(socket, __MODULE__))}
    end
  end

  def handle_params(%{"messages" => "inbox"}, _url, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}

      _user ->
        {:noreply, assign(socket, nav: :inbox, page_title: "Inbox", child_pid: nil)}
    end
  end

  def handle_params(%{"messages" => "new"}, _url, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}

      _user ->
        {:noreply, assign(socket, nav: :new_message, page_title: "New Message", child_pid: nil)}
    end
  end

  def handle_params(%{"confirm" => token}, _url, socket) do
    # Do not log in the user after confirmation to avoid a
    # leaked token giving the user access to the account.
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account confirmed successfully.")
         |> redirect(to: "/users/log_in")}

      :error ->
        {:noreply, user_confirm_error_redirect(socket)}
    end
  end

  def handle_params(%{"confirm_email" => token}, _url, socket) do
    case Accounts.update_user_email(socket.assigns.current_user, token) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Email changed successfully.")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}

      :error ->
        {:noreply,
         socket
         |> put_flash(:error, "Email change link is invalid or it has expired.")
         |> push_redirect(to: Routes.live_path(socket, __MODULE__))}
    end
  end

  def handle_params(params, _url, socket) when params == %{} do
    {:noreply, assign(socket, nav: :main, page_title: "Board Index", child_pid: nil)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, assign_invalid(socket)}

  # This duplicate event gets sent to the parent LV when the InfiniteScroll hook
  # gets triggered from the child LV.
  def handle_event("load_more", _params, socket), do: {:noreply, socket}

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {:noreply,
     socket
     |> handle_leaves(diff.leaves)
     |> handle_joins(diff.joins)}
  end

  def handle_info({:child_pid, pid}, socket) do
    {:noreply, assign(socket, child_pid: pid)}
  end

  def handle_info({:update_post_list, post}, socket) do
    {:noreply, assign(socket, post_list: [post])}
  end

  def handle_info({:unread_messages, fun}, socket) do
    {:noreply, update(socket, :unread_messages, fun)}
  end

  def handle_info({:updated_user, user}, %{assigns: %{child_pid: c_pid}} = socket) do
    if c_pid, do: send(c_pid, {:updated_user, user})

    {:noreply, assign(socket, current_user: user)}
  end

  def handle_info({:updated_theme, user}, socket) do
    bg_color = StyleHelpers.get_theme_background(user)
    {:noreply, assign(socket, current_user: user, bg_color: bg_color)}
  end

  def assign_invalid(socket) do
    assign(socket, nav: :invalid, page_title: "404 Page Not Found", child_pid: nil)
  end

  def assign_defaults(socket) do
    socket
    |> assign(users_online: %{})
    |> assign(topic_queue: [])
    |> assign(active_subscription: nil)
    |> assign(child_pid: nil)
    |> handle_joins(Presence.list(@presence))
  end

  def is_admin?(nil), do: false
  def is_admin?(%User{} = user), do: user.admin

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      assign(socket, :users_online, Map.put(socket.assigns.users_online, user, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users_online, Map.delete(socket.assigns.users_online, user))
    end)
  end

  defp resubscribe(socket, new_key) do
    if socket.assigns.active_subscription do
      Phoenix.PubSub.unsubscribe(PhxBb.PubSub, socket.assigns.active_subscription)
    end

    Phoenix.PubSub.subscribe(PhxBb.PubSub, new_key)
    assign(socket, active_subscription: new_key)
  end

  def user_confirm_error_redirect(socket) do
    case socket.assigns do
      %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        push_redirect(socket, to: "/forum")

      %{} ->
        socket
        |> put_flash(:error, "Account confirmation link is invalid or it has expired.")
        |> redirect(to: "/forum")
    end
  end

  def guest_id, do: 0 - System.unique_integer([:positive])

  ## Tailwind Styles

  def main_header_style(user), do: ["text-3xl text-center p-4 ", StyleHelpers.text_theme(user)]

  ## Function Components

  def link_to_index(current_user) do
    live_patch("Board Index",
      to: Routes.live_path(Endpoint, __MODULE__),
      class: StyleHelpers.link_style(current_user),
      id: "crumb-index-link"
    )
  end

  def link_to_board(board, current_user) do
    live_patch(board.name,
      to: Routes.live_path(Endpoint, __MODULE__, board: board.id),
      class: StyleHelpers.link_style(current_user),
      id: "crumb-board-link"
    )
  end

  def link_to_inbox(current_user) do
    live_patch("Inbox",
      to: Routes.live_path(Endpoint, __MODULE__, messages: "inbox"),
      id: "crumb-inbox-link",
      class: StyleHelpers.link_style(current_user)
    )
  end
end
