defmodule PhxBbWeb.PageLive do
  use PhxBbWeb, :live_view

  alias PhxBb.Posts.Post
  alias PhxBb.Posts
  alias PhxBb.Accounts
  alias PhxBb.Boards
  alias PhxBb.Replies.Reply
  alias PhxBb.Replies


  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(user_token: session["user_token"])
      |> main_helper(0)

    {:ok, socket}
  end

  def handle_event("show_board", %{"id" => id, "name" => name}, socket) do
    socket =
      socket
      |> assign(active_board_id: id)
      |> assign(active_board_name: name)
      |> board_helper(id, name)

    {:noreply, socket}
  end

  def handle_event("show_post", %{"id" => id}, socket) do
    socket = post_helper(socket, id)

    {:noreply, socket}
  end

  def handle_event("goto_post", params, socket) do
    socket =
      socket
      |> assign(active_board_id: params["board"])
      |> assign(active_board_name: params["bname"])
      |> post_helper(params["post"])

    {:noreply, socket}
  end

  def handle_event("return_main", _params, socket) do
    {:noreply, main_helper(socket, 1)}
  end

  def handle_event("return_board", _params, socket) do
    board_id = socket.assigns.active_board_id
    board_name = socket.assigns.active_board_name
    socket =
      socket
      |> assign(active_post: nil)
      |> board_helper(board_id, board_name)

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
        0 -> Accounts.build_cache(users, %{nil => %{name: "Unknown User"}})
        1 -> Accounts.build_cache(users, socket.assigns.user_cache)
      end

    socket
    |> assign(nav: :main)
    |> assign(board_list: boards)
    |> assign(post_list: [])
    |> assign(active_board_id: nil)
    |> assign(active_board_name: nil)
    |> assign(active_post: nil)
    |> assign(user_cache: cache)
    |> assign(page_title: "Board Index")
  end

  defp board_helper(socket, board_id, board_name) do
    posts = Posts.list_posts(board_id)
    cache =
      Enum.reduce(posts, [], fn p, acc -> [p.last_user | [p.author | acc]] end)
      |> Accounts.build_cache(socket.assigns.user_cache)

    socket
    |> assign(nav: :board)
    |> assign(post_list: posts)
    |> assign(changeset: Posts.change_post(%Post{}))
    |> assign(page_title: board_name)
    |> assign(user_cache: cache)
  end

  defp post_helper(socket, post_id) do
    post = Posts.get_post!(post_id)
    replies = Replies.list_replies(post_id)
    user_ids = Enum.map(replies, fn reply -> reply.author end)
    cache = Accounts.build_cache(user_ids, socket.assigns.user_cache)

    socket
    |> assign(nav: :post)
    |> assign(user_cache: cache)
    |> assign(page_title: post.title)
    |> assign(changeset: Replies.change_reply(%Reply{}))
    |> assign(reply_list: replies)
    |> assign(active_post: post)
  end

  defp current_user_id(socket) do
    Accounts.get_user_by_session_token(socket.assigns.user_token).id
  end
end
