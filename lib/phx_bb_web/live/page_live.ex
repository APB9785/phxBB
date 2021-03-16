defmodule PhxBbWeb.PageLive do
  use PhxBbWeb, :live_view

  alias PhxBb.Posts.Post
  alias PhxBb.Posts
  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBb.Boards
  alias PhxBb.Replies.Reply
  alias PhxBb.Replies


  ############   MAIN VIEW   ############

  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(user_token: session["user_token"])
      |> main_helper(0)

    {:ok, socket}
  end

  def handle_event("return_main", _params, socket) do
    {:noreply, main_helper(socket, 1)}
  end

  # Option 0 for first mount, Option 1 for returning to Main Index later
  defp main_helper(socket, option) do
    boards = Boards.list_boards()
    users =
      Enum.reduce(boards, [], fn b, acc ->
        case b.last_user do
          nil -> acc
          last_user -> [last_user | acc]
        end
      end)
    cache =
      case option do
        0 -> Accounts.build_cache(users, %{nil => %User{username: "Unknown User"}})
        1 -> Accounts.build_cache(users, socket.assigns.user_cache)
      end

    socket
    |> assign(board_list: boards)
    |> assign(post_list: [])
    |> assign(active_board_id: nil)
    |> assign(active_board_name: nil)
    |> assign(active_post: nil)
    |> assign(user_cache: cache)
    |> assign(page_title: "Board Index")
  end

  ############   BOARD VIEW   ############

  def handle_event("show_board", %{"id" => id, "name" => name}, socket) do
    posts = Posts.list_posts(id)
    cache =
      Enum.reduce(posts, [], fn p, acc -> [p.last_user | [p.author | acc]] end)
      |> Accounts.build_cache(socket.assigns.user_cache)

    socket =
      socket
      |> assign(active_board_id: id)
      |> assign(active_board_name: name)
      |> assign(post_list: posts)
      |> assign(changeset: Posts.change_post(%Post{}))
      |> assign(page_title: name)
      |> assign(user_cache: cache)

    {:noreply, socket}
  end

  def handle_event("return_board", _params, socket) do
    socket =
      socket
      |> assign(active_post: nil)
      |> assign(post_list: Posts.list_posts(socket.assigns.active_board_id))
      |> assign(changeset: Posts.change_post(%Post{}))
      |> assign(page_title: socket.assigns.active_board_name)

    {:noreply, socket}
  end

  def handle_event("new_post", %{"post" => params}, socket) do
    b_id = socket.assigns.active_board_id
    u_id = current_user_id(socket)
    params =
      params
      |> Map.put("board_id", b_id)
      |> Map.put("author", u_id)
      |> Map.put("last_user", u_id)

    case Posts.create_post(params) do
      {:ok, post} ->
        socket =
          socket
          |> assign(post_list: Posts.list_posts(b_id))
          |> assign(changeset: Posts.change_post(%Post{}))

        current_board = Boards.get_board!(b_id)
        changes =
          %{
            "last_post" => post.id,
            "last_user" => u_id,
            "topic_count" => current_board.topic_count + 1,
            "post_count" => current_board.post_count + 1
          }

        {:ok, _} = Boards.update_board(current_board, changes)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  # Delete Post handler - not in use
  # def handle_event("delete_post", _params, socket) when socket.assigns.user_token == nil do
  #   {:noreply, socket}
  # end
  # def handle_event("delete_post", %{"id" => id}, socket) do
  #
  #   case Posts.delete_post_by_id(id) do
  #     {:ok, _struct}       -> # Deleted with success
  #       socket =
  #         assign(socket, post_list: Posts.list_posts(socket.assigns.board_select))
  #       {:noreply, socket}
  #
  #     {:error, _changeset} -> # Something went wrong
  #       {:noreply, socket}
  #   end
  # end

  ############   POST VIEW   ############

  def handle_event("show_post", %{"id" => id}, socket) do
    replies = Replies.list_replies(id)
    post = Posts.get_post!(id)
    user_ids = Enum.map(replies, fn reply -> reply.author end)
    cache = Accounts.build_cache(user_ids, socket.assigns.user_cache)

    socket =
      socket
      |> assign(active_post: post)
      |> assign(reply_list: replies)
      |> assign(changeset: Replies.change_reply(%Reply{}))
      |> assign(user_cache: cache)
      |> assign(page_title: post.title)

    {:noreply, socket}
  end

  def handle_event("new_reply", %{"reply" => params}, socket) do
    u_id = current_user_id(socket)
    post = socket.assigns.active_post
    current_board = Boards.get_board!(socket.assigns.active_board_id)
    params =
      params
      |> Map.put("post_id", post.id)
      |> Map.put("author", u_id)

    case Replies.create_reply(params) do
      {:ok, _reply} ->
        socket =
          socket
          |> assign(reply_list: Replies.list_replies(post.id))
          |> assign(changeset: Replies.change_reply(%Reply{}))

        # Update the last reply info for the active post
        {:ok, _} = Posts.update_post(post, %{"last_user" => u_id})

        # Update the last post info for the active board
        board_changes =
          %{
            "last_post" => post.id,
            "last_user" => u_id,
            "post_count" => current_board.post_count + 1
          }
        {:ok, _} = Boards.update_board(current_board, board_changes)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end


  defp current_user_id(socket) do
    Accounts.get_user_by_session_token(socket.assigns.user_token).id
  end
end
