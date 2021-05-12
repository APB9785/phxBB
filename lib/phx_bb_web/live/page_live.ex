defmodule PhxBbWeb.PageLive do
  @moduledoc """
  This is the main LiveView which renders the forum.
  """

  use PhxBbWeb, :live_view

  import PhxBbWeb.LiveHelpers
  import PhxBbWeb.StyleHelpers

  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Posts
  alias PhxBb.Replies
  alias PhxBb.Replies.Reply
  alias PhxBbWeb.BoardComponent
  alias PhxBbWeb.BreadcrumbComponent
  alias PhxBbWeb.CreatePostComponent
  alias PhxBbWeb.MainIndexComponent
  alias PhxBbWeb.NewReplyComponent
  alias PhxBbWeb.TopicComponent
  alias PhxBbWeb.UserMenuComponent
  alias PhxBbWeb.UserProfileComponent
  alias PhxBbWeb.UserRegistrationComponent
  alias PhxBbWeb.UserSettingsComponent

  def mount(_params, session, socket) do
    if connected?(socket) do
      Replies.subscribe()
      Accounts.subscribe()
      Posts.subscribe()
    end

    case lookup_token(session["user_token"]) do
      nil ->
        # User is logged out
        socket =
          socket
          |> assign(active_user: nil)
          |> assign(user_cache: %{})
          |> assign(bg_color: get_default_background())
          |> assign_defaults

        {:ok, socket}

      user ->
        # User is logged in
        socket =
          socket
          |> assign(bg_color: get_theme_background(user))
          |> assign(active_user: user)
          |> assign(user_cache: %{user.id => cache_self(user)})
          |> assign_defaults
          |> allow_upload(:avatar,
            accept: ~w(.png .jpeg .jpg),
            max_entries: 1,
            max_file_size: 100_000
          )

        {:ok, socket}
    end
  end

  def handle_params(%{"create_post" => "1", "board" => _}, _url, socket)
      when is_nil(socket.assigns.active_user) do
    socket = push_redirect(socket, to: "/users/log_in")
    {:noreply, socket}
  end

  def handle_params(%{"create_post" => "1", "board" => board_id}, _url, socket) do
    # No need to query database for Board info
    if active_assign_outdated?(:board, board_id, socket) do
      socket = assign_create_full_query(socket, board_id)
      {:noreply, socket}
    else
      socket = assign(socket, nav: :create_post, page_title: "Create Post")
      {:noreply, socket}
    end
  end

  def handle_params(%{"post" => post_id}, _url, socket) do
    # No need to query database for Post info
    if active_assign_outdated?(:post, post_id, socket) do
      socket = assign_post_full_query(socket, post_id)
      {:noreply, socket}
    else
      socket = assign_post_nav(socket, socket.assigns.active_post)
      {:noreply, socket}
    end
  end

  def handle_params(%{"board" => board_id}, _url, socket) do
    # No need to query database for Board info
    if active_assign_outdated?(:board, board_id, socket) do
      socket = assign_board_full_query(socket, board_id)
      {:noreply, socket}
    else
      socket = assign(socket, nav: :board, page_title: socket.assigns.active_board.name)
      {:noreply, socket}
    end
  end

  def handle_params(%{"user" => user_id}, _url, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        socket = assign_invalid(socket)
        {:noreply, socket}

      user ->
        socket = assign(socket, nav: :user_profile, page_title: user.username, view_user: user)
        {:noreply, socket}
    end
  end

  def handle_params(%{"register" => "1"}, _url, socket) do
    if is_nil(socket.assigns.active_user) do
      socket = assign(socket, nav: :register, page_title: "Register")
      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(:info, "You are already registered and logged in.")
        |> push_patch(to: Routes.live_path(socket, __MODULE__))

      {:noreply, socket}
    end
  end

  def handle_params(%{"settings" => "1"}, _url, socket) do
    case socket.assigns.active_user do
      nil ->
        socket = push_redirect(socket, to: "/users/log_in")
        {:noreply, socket}

      _user ->
        socket = assign(socket, nav: :settings, page_title: "User Settings")
        {:noreply, socket}
    end
  end

  def handle_params(%{"confirm" => token}, _url, socket) do
    # Do not log in the user after confirmation to avoid a
    # leaked token giving the user access to the account.
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Account confirmed successfully.")
          |> redirect(to: "/users/log_in")

        {:noreply, socket}

      :error ->
        socket = user_confirm_error_redirect(socket)
        {:noreply, socket}
    end
  end

  def handle_params(%{"confirm_email" => token}, _url, socket) do
    case Accounts.update_user_email(socket.assigns.active_user, token) do
      :ok ->
        socket =
          socket
          |> put_flash(:info, "Email changed successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__))

        {:noreply, socket}

      :error ->
        socket =
          socket
          |> put_flash(:error, "Email change link is invalid or it has expired.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__))

        {:noreply, socket}
    end
  end

  def handle_params(params, _url, socket) when params == %{} do
    socket = assign(socket, nav: :main, page_title: "Board Index")
    {:noreply, socket}
  end

  def handle_params(_params, _url, socket) do
    socket = assign_invalid(socket)
    {:noreply, socket}
  end

  # Local LiveView helpers for Components

  def handle_info({:updated_user, user}, socket) do
    socket = assign(socket, active_user: user)
    {:noreply, socket}
  end

  def handle_info({:updated_theme, user}, socket) do
    socket =
      assign(socket,
        active_user: user,
        bg_color: get_theme_background(user)
      )

    {:noreply, socket}
  end

  def handle_info({:backend_delete_reply, %Reply{id: reply_id} = reply}, socket) do
    board = socket.assigns.active_board
    active_post = socket.assigns.active_post
    # Reply has already been removed from the DB
    case Enum.reverse(socket.assigns.reply_list) do
      [%Reply{id: ^reply_id}] ->
        # Give OP info to Post as latest
        Posts.deleted_only_reply(active_post)
        # Find second-to-last post/reply for Board
        [next_post] = Posts.most_recent_post(board.id)
        Boards.deleted_latest_reply(board.id, next_post)
        # Remove the reply from all viewers' assigns
        new_reply_list = []
        message = {:deleted_reply, new_reply_list, active_post.id, next_post}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

      [%Reply{id: ^reply_id} | [next | rest]] ->
        # Give second-to-last reply to the Post
        Posts.deleted_last_reply(reply.post_id, next.author, next.inserted_at)
        # Find second-to-last post/reply for Board
        [next_post] = Posts.most_recent_post(board.id)
        Boards.deleted_latest_reply(board.id, next_post)
        # Remove the reply from all viewers' assigns
        new_reply_list = [next | rest]
        message = {:deleted_reply, new_reply_list, active_post.id, next_post}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

      reversed_reply_list ->
        # Decrement Post's reply count
        Posts.deleted_reply(reply.post_id)
        # Decrement Board's reply count
        Boards.deleted_reply(board.id)
        # Remove the reply from all viewers' assigns
        new_reply_list =
          Enum.reject(reversed_reply_list, &(&1.id == reply_id))
          |> Enum.reverse()

        [next_post] = Posts.most_recent_post(board.id)
        message = {:deleted_reply, new_reply_list, active_post.id, next_post}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)
    end

    # Decrement author's post count
    Accounts.deleted_post(reply.author)

    {:noreply, socket}
  end

  # Global PubSub message handlers

  def handle_info({:deleted_reply, new_reply_list, post_id, next_post}, socket) do
    new_board_list =
      update_board_list(socket.assigns.board_list, next_post.board_id,
        post_count: &(&1 - 1),
        last_post: fn _ -> next_post.id end,
        last_user: fn _ -> next_post.last_user end,
        updated_at: fn _ -> NaiveDateTime.utc_now() end
      )

    socket =
      socket
      |> delete_reply(new_reply_list, post_id)
      |> assign(board_list: new_board_list)

    {:noreply, socket}
  end

  def handle_info({:edited_reply, new_reply}, socket) do
    socket = edit_reply(socket, new_reply)
    {:noreply, socket}
  end

  def handle_info({:edited_post, new_post}, socket) do
    socket = edit_post(socket, new_post)
    {:noreply, socket}
  end

  def handle_info({:user_avatar_change, user_id, avatar}, socket) do
    socket = update_cache(socket, user_id, :avatar, avatar)
    {:noreply, socket}
  end

  def handle_info({:user_title_change, user_id, title}, socket) do
    socket = update_cache(socket, user_id, :title, title)
    {:noreply, socket}
  end

  def handle_info({:new_reply, reply, board_id}, socket) do
    new_board_list =
      update_board_list(socket.assigns.board_list, board_id,
        post_count: &(&1 + 1),
        last_post: fn _ -> reply.post_id end,
        last_user: fn _ -> reply.author end,
        updated_at: fn _ -> NaiveDateTime.utc_now() end
      )

    socket =
      socket
      |> add_reply(reply.post_id, reply)
      |> assign(board_list: new_board_list)
      |> update_cache_post_count(reply.author)

    {:noreply, socket}
  end

  def handle_info({:new_topic, author_id, post_id, board_id}, socket) do
    new_board_list =
      update_board_list(socket.assigns.board_list, board_id,
        topic_count: &(&1 + 1),
        post_count: &(&1 + 1),
        last_post: fn _ -> post_id end,
        last_user: fn _ -> author_id end,
        updated_at: fn _ -> NaiveDateTime.utc_now() end
      )

    socket =
      socket
      |> update_cache_post_count(author_id)
      |> assign(board_list: new_board_list)

    {:noreply, socket}
  end

  # Helpers for the above handlers

  def update_board_list(board_list, board_id, changes) do
    Enum.map(board_list, fn b ->
      if b.id == board_id do
        Enum.reduce(changes, b, fn {key, func}, acc ->
          Map.update!(acc, key, func)
        end)
      else
        b
      end
    end)
  end

  defp edit_post(socket, new_post) do
    cond do
      is_nil(socket.assigns[:active_post]) ->
        socket

      socket.assigns.active_post.id == new_post.id ->
        assign(socket, active_post: new_post)

      true ->
        socket
    end
  end

  defp edit_reply(socket, new_reply) do
    cond do
      is_nil(socket.assigns[:active_post]) ->
        socket

      socket.assigns.active_post.id == new_reply.post_id ->
        new_reply_list = replace_reply_list(socket.assigns.reply_list, new_reply)
        assign(socket, reply_list: new_reply_list)

      true ->
        socket
    end
  end

  defp delete_reply(socket, new_reply_list, post_id) do
    cond do
      is_nil(socket.assigns[:active_post]) ->
        socket

      socket.assigns.active_post.id == post_id ->
        assign(socket,
          reply_list: new_reply_list,
          active_board: Map.update!(socket.assigns.active_board, :post_count, &(&1 - 1)),
          active_post: Map.update!(socket.assigns.active_post, :reply_count, &(&1 - 1))
        )

      true ->
        socket
    end
  end

  defp add_reply(socket, post_id, reply) do
    cond do
      is_nil(socket.assigns[:active_post]) ->
        socket

      post_id == socket.assigns.active_post.id ->
        assign(socket,
          reply_list: socket.assigns.reply_list ++ [reply],
          active_board: Map.update!(socket.assigns.active_board, :post_count, &(&1 + 1)),
          active_post: Map.update!(socket.assigns.active_post, :reply_count, &(&1 + 1))
        )

      true ->
        socket
    end
  end

  defp replace_reply_list(reply_list, new_reply) do
    Enum.map(reply_list, fn reply ->
      if reply.id == new_reply.id, do: new_reply, else: reply
    end)
  end

  defp update_cache_post_count(socket, author_id) do
    case socket.assigns.user_cache do
      %{^author_id => user_info} = cache ->
        new_user_info = Map.update!(user_info, :post_count, &(&1 + 1))
        assign(socket, user_cache: Map.put(cache, author_id, new_user_info))

      _ ->
        socket
    end
  end

  defp update_cache(socket, user_id, key, value) do
    case socket.assigns.user_cache do
      %{^user_id => _} = cache ->
        new_cache = Map.update!(cache, user_id, &Map.put(&1, key, value))
        assign(socket, user_cache: new_cache)

      _ ->
        socket
    end
  end
end
