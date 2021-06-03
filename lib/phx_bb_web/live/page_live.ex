defmodule PhxBbWeb.PageLive do
  @moduledoc """
  This is the main LiveView which renders the forum.
  """

  use PhxBbWeb, :live_view

  import PhxBbWeb.LiveHelpers

  import PhxBbWeb.StyleHelpers,
    only: [
      content_background: 1,
      main_header_style: 1,
      link_style: 1,
      get_default_background: 0,
      get_theme_background: 1
    ]

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBb.Boards
  alias PhxBb.Boards.Board
  alias PhxBb.Posts
  alias PhxBb.Replies
  alias PhxBb.Replies.Reply
  alias PhxBbWeb.{Presence, UserCache}

  @presence "phx_bb:presence"

  def mount(_params, session, socket) do
    if connected?(socket) do
      Replies.subscribe()
      Accounts.subscribe()
      Posts.subscribe()
    end

    case Accounts.get_user_by_session_token(session["user_token"]) do
      nil ->
        # User is logged out
        if connected?(socket) do
          Presence.track(self(), @presence, guest_id(), %{name: "guest"})
          Phoenix.PubSub.subscribe(PhxBb.PubSub, @presence)
        end

        {:ok,
         socket
         |> assign(active_user: nil)
         |> assign(user_cache: %{})
         |> assign(bg_color: get_default_background())
         |> assign_defaults
         |> handle_joins(Presence.list(@presence))}

      user ->
        # User is logged in
        if connected?(socket) do
          Presence.track(self(), @presence, user.id, %{name: user.username})
          Phoenix.PubSub.subscribe(PhxBb.PubSub, @presence)
        end

        {:ok,
         socket
         |> assign(bg_color: get_theme_background(user))
         |> assign(active_user: user)
         |> assign(user_cache: %{user.id => UserCache.cache_self(user)})
         |> assign_defaults
         |> handle_joins(Presence.list(@presence))
         |> allow_upload(:avatar,
           accept: ~w(.png .jpeg .jpg),
           max_entries: 1,
           max_file_size: 100_000
         )}
    end
  end

  def handle_params(%{"create_post" => "1", "board" => _}, _url, socket)
      when is_nil(socket.assigns.active_user) do
    {:noreply, push_redirect(socket, to: "/users/log_in")}
  end

  def handle_params(%{"create_post" => "1", "board" => board_id}, _url, socket) do
    board_id = String.to_integer(board_id)

    if active_assign_outdated?(:board, board_id, socket) do
      {:noreply, assign_create_full_query(socket, board_id)}
    else
      # No need to query database for Board info
      {:noreply, assign(socket, nav: :create_post, page_title: "Create Post")}
    end
  end

  def handle_params(%{"post" => post_id}, _url, socket) do
    post_id = String.to_integer(post_id)

    if active_assign_outdated?(:post, post_id, socket) do
      {:noreply, assign_post_full_query(socket, post_id)}
    else
      # No need to query database for Post info
      {:noreply, assign_post_nav(socket, socket.assigns.active_post)}
    end
  end

  def handle_params(%{"board" => board_id}, _url, socket) do
    board_id = String.to_integer(board_id)

    if active_assign_outdated?(:board, board_id, socket) do
      {:noreply, assign_board_full_query(socket, board_id)}
    else
      # No need to query database for Board info
      {:noreply, assign(socket, nav: :board, page_title: socket.assigns.active_board.name)}
    end
  end

  def handle_params(%{"user" => user_id}, _url, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        {:noreply, assign_invalid(socket)}

      user ->
        {:noreply, assign(socket, nav: :user_profile, page_title: user.username, view_user: user)}
    end
  end

  def handle_params(%{"register" => "1"}, _url, socket) do
    if is_nil(socket.assigns.active_user) do
      {:noreply, assign(socket, nav: :register, page_title: "Register")}
    else
      {:noreply,
       socket
       |> put_flash(:info, "You are already registered and logged in.")
       |> push_patch(to: Routes.live_path(socket, __MODULE__))}
    end
  end

  def handle_params(%{"settings" => "1"}, _url, socket) do
    case socket.assigns.active_user do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}

      _user ->
        {:noreply, assign(socket, nav: :settings, page_title: "User Settings")}
    end
  end

  def handle_params(%{"admin" => "1"}, _url, socket) do
    user = socket.assigns.active_user

    if !is_nil(user) and user.admin do
      {:noreply, assign(socket, nav: :admin, page_title: "Admin Panel")}
    else
      {:noreply, assign_invalid(socket)}
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
    case Accounts.update_user_email(socket.assigns.active_user, token) do
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
    {:noreply,
     assign(socket, nav: :main, page_title: "Board Index", active_board: nil, active_post: nil)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, assign_invalid(socket)}

  # Local LiveView helpers for Components

  def handle_info({:updated_user, user}, socket) do
    {:noreply, assign(socket, active_user: user)}
  end

  def handle_info({:updated_theme, user}, socket) do
    {:noreply, assign(socket, active_user: user, bg_color: get_theme_background(user))}
  end

  def handle_info({:backend_delete_reply, %Reply{id: reply_id} = reply}, socket) do
    board = socket.assigns.active_board
    active_post = socket.assigns.active_post
    {:ok, _} = Replies.delete_reply(reply)

    # Don't change the order of any function calls below!
    case Enum.reverse(socket.assigns.reply_list) do
      [%Reply{id: ^reply_id}] ->
        # There was only one reply
        Posts.deleted_only_reply(active_post)
        top_post = Posts.most_recent_post(board.id)
        Boards.deleted_latest_reply(board.id, top_post)
        new_reply_list = []
        message = {:deleted_reply, reply.author, new_reply_list, active_post.id, top_post}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

      [%Reply{id: ^reply_id} | [next | rest]] ->
        # The deleted reply was the most recent among other(s)
        Posts.deleted_last_reply(reply.post_id, next.author, next.inserted_at)
        top_post = Posts.most_recent_post(board.id)
        Boards.deleted_latest_reply(board.id, top_post)
        new_reply_list = Enum.reverse([next | rest])
        message = {:deleted_reply, reply.author, new_reply_list, active_post.id, top_post}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)

      reversed_reply_list ->
        # There have been other replies made to the topic since this one
        Posts.deleted_reply(reply.post_id)
        top_post = Posts.most_recent_post(board.id)
        Boards.deleted_reply(board.id)
        new_reply_list = Enum.reject(reversed_reply_list, &(&1.id == reply_id)) |> Enum.reverse()
        message = {:deleted_reply, reply.author, new_reply_list, active_post.id, top_post}
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "replies", message)
    end

    # Decrement author's post count
    Accounts.deleted_post(reply.author)

    {:noreply, socket}
  end

  # Global PubSub message handlers

  def handle_info({:deleted_reply, author_id, new_reply_list, post_id, top_post}, socket) do
    new_board_list =
      update_board_list(socket.assigns.board_list, top_post.board_id,
        post_count: &(&1 - 1),
        last_post: fn _ -> top_post.id end,
        last_user: fn _ -> top_post.last_user end,
        updated_at: fn _ -> top_post.last_reply_at end
      )

    {:noreply,
     socket
     |> delete_reply_from_post(new_reply_list, post_id)
     |> refresh_post_list(top_post.board_id)
     |> update_cache_post_count(author_id, &(&1 - 1))
     |> assign(board_list: new_board_list)}
  end

  def handle_info({:edited_reply, new_reply}, socket) do
    cond do
      is_nil(socket.assigns[:active_post]) ->
        {:noreply, socket}

      socket.assigns.active_post.id == new_reply.post_id ->
        new_reply_list = replace_reply_list(socket.assigns.reply_list, new_reply)
        {:noreply, assign(socket, reply_list: new_reply_list)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info({:edited_post, new_post}, socket) do
    cond do
      is_nil(socket.assigns[:active_post]) ->
        {:noreply, socket}

      socket.assigns.active_post.id == new_post.id ->
        {:noreply, assign(socket, active_post: new_post)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info({:user_avatar_change, user_id, avatar}, socket) do
    {:noreply, update_cache(socket, user_id, :avatar, avatar)}
  end

  def handle_info({:user_title_change, user_id, title}, socket) do
    {:noreply, update_cache(socket, user_id, :title, title)}
  end

  def handle_info({:new_reply, reply, board_id}, socket) do
    new_board_list =
      update_board_list(socket.assigns.board_list, board_id,
        post_count: &(&1 + 1),
        last_post: fn _ -> reply.post_id end,
        last_user: fn _ -> reply.author end,
        updated_at: fn _ -> NaiveDateTime.utc_now() end
      )

    {:noreply,
     socket
     |> add_reply(reply.post_id, reply)
     |> refresh_post_list(board_id)
     |> assign(board_list: new_board_list)
     |> update_cache_post_count(reply.author, &(&1 + 1))}
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

    {:noreply,
     socket
     |> update_cache_post_count(author_id, &(&1 + 1))
     |> refresh_post_list(board_id)
     |> assign(board_list: new_board_list)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {:noreply,
     socket
     |> handle_leaves(diff.leaves)
     |> handle_joins(diff.joins)}
  end

  def handle_info({:user_disabled, user_id}, socket) do
    case socket.assigns.active_user do
      %User{id: ^user_id} = user ->
        new_user = Map.put(user, :disabled_at, NaiveDateTime.utc_now())
        {:noreply, assign(socket, active_user: new_user)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info({:user_enabled, user_id}, socket) do
    case socket.assigns.active_user do
      %User{id: ^user_id} = user ->
        new_user = Map.put(user, :disabled_at, nil)
        {:noreply, assign(socket, active_user: new_user)}

      _ ->
        {:noreply, socket}
    end
  end

  # Helpers for the above handlers

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

  def update_board_list(board_list, board_id, changes) do
    Enum.map(board_list, fn
      %Board{id: ^board_id} = board ->
        Enum.reduce(changes, board, fn {key, func}, acc -> Map.update!(acc, key, func) end)

      board ->
        board
    end)
  end

  defp delete_reply_from_post(socket, new_reply_list, post_id) do
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

  defp refresh_post_list(socket, board_id) do
    active_board = socket.assigns.active_board

    if !is_nil(active_board) and active_board.id == board_id do
      post_list = Posts.list_posts(board_id)
      cache = UserCache.from_post_list(post_list, socket.assigns.user_cache)
      assign(socket, post_list: post_list, user_cache: cache)
    else
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
          active_post: Map.update!(socket.assigns.active_post, :reply_count, &(&1 + 1)),
          user_cache: UserCache.single_user(reply.author, socket.assigns.user_cache)
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

  defp update_cache_post_count(socket, author_id, func) do
    case socket.assigns.user_cache do
      %{^author_id => user_info} = cache ->
        new_user_info = Map.update!(user_info, :post_count, func)
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
