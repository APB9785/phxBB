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
      |> assign(user_cache: %{nil => %{name: "Unknown User"}})

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    socket =
      case params do
        %{"create_post" => "1", "board" => board_id} -> create_post_helper(socket, board_id)
        %{"post" => post_id} -> post_helper(socket, post_id)
        %{"board" => board_id} -> board_helper(socket, board_id)
        %{} -> main_helper(socket)
      end

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
        current_board = Boards.get_board!(b_id)
        changes =
          %{
            "last_post" => post.id,
            "last_user" => u_id,
            "topic_count" => current_board.topic_count + 1,
            "post_count" => current_board.post_count + 1
          }

        {:ok, _} = Boards.update_board(current_board, changes)

        {:noreply,
         socket
         |> push_patch(to: Routes.live_path(socket, __MODULE__, board: b_id))}

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
    posts = Posts.list_posts(board_id)
    name = Boards.get_name(board_id)
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

  defp post_helper(socket, post_id) do
    post = Posts.get_post!(post_id)
    replies = Replies.list_replies(post_id)
    user_ids = Enum.map(replies, fn reply -> reply.author end)
    cache = Accounts.build_cache([post.author | user_ids], socket.assigns.user_cache)

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

  defp create_post_helper(socket, board_id) do
    socket =
      if socket.assigns[:active_board_id] != board_id do
        socket
        |> assign(active_board_id: board_id)
        |> assign(active_board_name: Boards.get_name(board_id))
      else
        socket
      end

    socket
    |> assign(nav: :create_post)
    |> assign(page_title: "Create Post")
    |> assign(changeset: Posts.change_post(%Post{}))
  end

  defp current_user_id(socket) do
    Accounts.get_user_by_session_token(socket.assigns.user_token).id
  end

  defp month_abv(n) do
    case n do
      1 -> "Jan"
      2 -> "Feb"
      3 -> "Mar"
      4 -> "Apr"
      5 -> "May"
      6 -> "Jun"
      7 -> "Jul"
      8 -> "Aug"
      9 -> "Sep"
      10 -> "Oct"
      11 -> "Nov"
      12 -> "Dec"
    end
  end

  def format_date(ndt) do
    date = NaiveDateTime.to_date(ndt)
    month_abv(date.month) <> " " <> Integer.to_string(date.day) <>
      ", " <> Integer.to_string(date.year)
  end

  def format_time(ndt) do
    month = month_abv(ndt.month)
    ampm = if ndt.hour > 11 do "pm" else "am" end
    hour =
      case ndt.hour do
        0 -> "12"
        x when x > 12 -> Integer.to_string(x - 12)
        x -> Integer.to_string(x)
      end
    minute = Integer.to_string(ndt.minute) |> String.pad_leading(2, "0")

    month <> " " <> Integer.to_string(ndt.day) <> ", " <>
      Integer.to_string(ndt.year) <> "  " <> hour <> ":" <> minute <> " " <> ampm
  end

  def format_time(ndt, offset) do
    ndt
    |> NaiveDateTime.add(offset * 3600)
    |> format_time
  end
end
