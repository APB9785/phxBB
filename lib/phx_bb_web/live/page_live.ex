defmodule PhxBbWeb.PageLive do
  use PhxBbWeb, :live_view

  alias PhxBb.Posts.Post
  alias PhxBb.Posts
  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Replies.Reply
  alias PhxBb.Replies

  import PhxBbWeb.LiveHelpers


  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(user_token: session["user_token"])
      |> assign(user_cache: %{nil => %{name: "Unknown User"}})

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    socket =
      case params do
        %{"create_post" => "1", "board" => board_id} -> create_post_helper(socket, board_id)
        %{"post" => post_id} -> post_helper(socket, post_id)
        %{"board" => board_id} -> board_helper(socket, board_id)
        map when map == %{} -> main_helper(socket)
        %{} -> invalid_helper(socket)
      end

    {:noreply, socket}
  end


  def handle_event("new_post", %{"post" => params}, socket) do
    case socket.assigns.user_token do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}
      token ->
        u_id = lookup_token(token)
        b_id = socket.assigns.active_board_id
        case postmaker(params["body"], params["title"], b_id, u_id) do
          {:ok, post} ->
            # Update the last post info for the active board
            {1, _} = Boards.added_post(b_id, post.id, u_id)
            # Update the user's post count
            {1, _} = Accounts.added_post(u_id)

            {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, board: b_id))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end
    end
  end

  def handle_event("new_reply", %{"reply" => params}, socket) do
    case socket.assigns.user_token do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}
      token ->
        u_id = lookup_token(token)
        post = socket.assigns.active_post
        case replymaker(params["body"], post.id, u_id) do
          {:ok, _reply} ->
            socket =
              socket
              |> assign(reply_list: Replies.list_replies(post.id))
              |> assign(changeset: Replies.change_reply(%Reply{}))

            # Update the last reply info for the active post
            {1, _} = Posts.added_reply(post.id, u_id)

            # Update the last post info for the active board
            {1, _} =
              Boards.added_reply(socket.assigns.active_board_id, post.id, u_id)

            # Update the user's post count
            {1, _} = Accounts.added_post(u_id)

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            socket = assign(socket, changeset: changeset)
            {:noreply, socket}
        end
    end
  end

  defp main_helper(socket) do
    boards = Boards.list_boards()
    users =
      Enum.reduce(boards, [], fn b, acc ->
        case b.last_user do
          nil -> acc
          last_user -> [last_user | acc]
        end
      end)
    cache = Accounts.build_cache(users, socket.assigns.user_cache)

    socket
    |> assign(page_title: "Board Index")
    |> assign(nav: :main)
    |> assign(board_list: boards)
    |> assign(post_list: [])
    |> assign(active_board_id: nil)
    |> assign(active_board_name: nil)
    |> assign(active_post: nil)
    |> assign(user_cache: cache)
  end

  defp board_helper(socket, board_id) do
    case Boards.get_name(board_id) do
      nil ->
        invalid_helper(socket)
      name ->
        posts = Posts.list_posts(board_id)
        cache =
          Enum.reduce(posts, [], fn p, acc -> [p.last_user | [p.author | acc]] end)
          |> Accounts.build_cache(socket.assigns.user_cache)

        socket
        |> assign(nav: :board)
        |> assign(post_list: posts)
        |> assign(changeset: Posts.change_post(%Post{}))
        |> assign(page_title: name)
        |> assign(user_cache: cache)
        |> assign(active_board_id: board_id)
        |> assign(active_board_name: name)
    end
  end

  defp post_helper(socket, post_id) do
    case Posts.get_post(post_id) do
      nil ->
        invalid_helper(socket)
      post ->
        replies = Replies.list_replies(post_id)
        user_ids = Enum.map(replies, fn reply -> reply.author end)
        cache = Accounts.build_cache([post.author | user_ids], socket.assigns.user_cache)

        # Increments post view count
        {1, _} = Posts.viewed(post_id)

        socket
        |> assign(nav: :post)
        |> assign(user_cache: cache)
        |> assign(page_title: post.title)
        |> assign(changeset: Replies.change_reply(%Reply{}))
        |> assign(reply_list: replies)
        |> assign(active_post: post)
        |> assign(active_board_id: post.board_id)
        |> assign(active_board_name: Boards.get_name(post.board_id))
    end
  end

  defp create_post_helper(socket, board_id) do
    if socket.assigns[:active_board_id] != board_id do
      # User got here via external link - must query DB for board info
      case Boards.get_name(board_id) do
        nil ->  # Board does not exist
          invalid_helper(socket)
        name ->  # Board exists, need to store info in assigns
          socket
          |> assign(active_board_id: board_id)
          |> assign(active_board_name: name)
          |> assign(nav: :create_post)
          |> assign(page_title: "Create Post")
          |> assign(changeset: Posts.change_post(%Post{}))
      end
    else
      # User got here from a valid board, no need to query DB or update assigns
      socket
      |> assign(nav: :create_post)
      |> assign(page_title: "Create Post")
      |> assign(changeset: Posts.change_post(%Post{}))
    end
  end

  defp invalid_helper(socket) do
    socket
    |> assign(nav: :invalid)
  end
end
