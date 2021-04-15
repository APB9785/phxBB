defmodule PhxBbWeb.PageLive do
  @moduledoc """
  This is the main LiveView which renders the forum.
  """

  use PhxBbWeb, :live_view

  import PhxBbWeb.LiveHelpers

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBb.Boards
  alias PhxBb.Posts
  alias PhxBb.Posts.Post
  alias PhxBb.Replies
  alias PhxBb.Replies.Reply

  def mount(_params, session, socket) do
    case lookup_token(session["user_token"]) do
      nil ->
        # User is logged out
        {:ok,
          socket
          |> assign(active_user: nil)
          |> assign(user_cache: %{})}

      user ->
        # User is logged in
        user_info = %{
          name: user.username,
          joined: user.inserted_at,
          title: user.title,
          avatar: user.avatar
        }

        {:ok,
          socket
          |> assign(active_user: user)
          |> assign(user_cache: %{user.id => user_info})
          |> allow_upload(:avatar,
            accept: ~w(.png .jpeg .jpg),
            max_entries: 1,
            max_file_size: 100_000
          )}
    end
  end

  def handle_params(%{"create_post" => "1", "board" => board_id}, _url, socket) do
    socket = create_post_helper(socket, board_id)

    {:noreply, socket}
  end
  def handle_params(%{"post" => post_id}, _url, socket) do
    {:noreply, post_helper(socket, post_id)}
  end
  def handle_params(%{"board" => board_id}, _url, socket) do
    {:noreply, board_helper(socket, board_id)}
  end
  def handle_params(%{"register" => "1"}, _url, socket) do
    {:noreply, registration_helper(socket)}
  end
  def handle_params(%{"settings" => "1"}, _url, socket) do
    {:noreply, settings_helper(socket)}
  end
  def handle_params(%{"confirm" => token}, _url, socket) do
    {:noreply, user_confirmation_helper(socket, token)}
  end
  def handle_params(%{"confirm_email" => token}, _url, socket) do
    {:noreply, email_update_helper(socket, token)}
  end
  def handle_params(params, _url, socket) when params == %{} do
    {:noreply, main_helper(socket)}
  end
  def handle_params(_params, _url, socket) do
    {:noreply, invalid_helper(socket)}
  end

  def handle_event("new_post", %{"post" => params}, socket) do
    case socket.assigns.active_user do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}

      user ->
        b_id = socket.assigns.active_board_id

        case postmaker(params["body"], params["title"], b_id, user.id) do
          {:ok, post} ->
            # Update the last post info for the active board
            {1, _} = Boards.added_post(b_id, post.id, user.id)
            # Update the user's post count
            {1, _} = Accounts.added_post(user.id)

            {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, board: b_id))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end
    end
  end

  def handle_event("new_reply", %{"reply" => params}, socket) do
    case socket.assigns.active_user do
      nil ->
        {:noreply, push_redirect(socket, to: "/users/log_in")}
      user ->
        post = socket.assigns.active_post
        case replymaker(params["body"], post.id, user.id) do
          {:ok, _reply} ->
            socket =
              socket
              |> assign(reply_list: Replies.list_replies(post.id))
              |> assign(changeset: Replies.change_reply(%Reply{}))

            # Update the last reply info for the active post
            {1, _} = Posts.added_reply(post.id, user.id)

            # Update the last post info for the active board
            {1, _} =
              Boards.added_reply(socket.assigns.active_board_id, post.id, user.id)

            # Update the user's post count
            {1, _} = Accounts.added_post(user.id)

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            socket = assign(socket, changeset: changeset)
            {:noreply, socket}
        end
    end
  end

  def handle_event("new_user", %{"user" => user_params}, socket) do
    user_params =
      user_params
      |> Map.put("post_count", 0)
      |> Map.put("title", "Registered User")

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        Accounts.deliver_user_confirmation_instructions(user,
          &(PhxBbWeb.Endpoint.url() <> "?confirm=" <> &1))

        {:noreply,
          socket
          |> put_flash(:info, "User created successfully. Please check your email for confirmation instructions.")
          |> redirect(to: Routes.user_session_path(socket, :new))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.active_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &(PhxBbWeb.Endpoint.url() <> "?confirm_email=" <> &1)
        )

        {:noreply,
          socket
          |> put_flash(:info, "A link to confirm your email change has been sent to the new address.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))}

      {:error, changeset} ->
        {:noreply, assign(socket, email_changeset: changeset)}
    end
  end

  def handle_event("change_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.active_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, _user} ->
        {:noreply,
          socket
          |> put_flash(:info, "Password updated successfully.  Please log in again.")
          |> redirect(to: Routes.user_session_path(socket, :new))}

      {:error, changeset} ->
        {:noreply, assign(socket, password_changeset: changeset)}
    end
  end

  def handle_event("change_timezone", %{"user" => params}, socket) do
    user = socket.assigns.active_user

    case Accounts.update_user_timezone(user, params) do
      {:ok, _user} ->
        {:noreply,
          socket
          |> put_flash(:info, "Timezone updated successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))}

      {:error, changeset} ->
        {:noreply, assign(socket, tz_changeset: changeset)}
    end
  end

  def handle_event("change_user_title", %{"user" => params}, socket) do
    user = socket.assigns.active_user

    case Accounts.update_user_title(user, params) do
      {:ok, _user} ->
        {:noreply,
          socket
          |> put_flash(:info, "User title updated successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))}

      {:error, changeset} ->
        {:noreply, assign(socket, title_changeset: changeset)}
    end
  end

  def handle_event("upload_avatar", _params, socket) do
    consume_uploaded_entries(socket, :avatar, fn meta, entry ->
      dest = Path.join("priv/static/uploads", filename(entry))
      File.cp!(meta.path, dest)
      Routes.static_path(socket, "/uploads/#{filename(entry)}")
    end)
    |> case do
      [] ->
        changeset =
          socket.assigns.avatar_changeset
          |> replace_error(:avatar, "no file was selected")
        {:noreply, assign(socket, avatar_changeset: changeset)}
      [avatar_link] ->
        user = socket.assigns.active_user

        # If the user is replacing an existing avatar, delete the old one
        if user.avatar do
          File.rm!("priv/static#{user.avatar}")
        end

        case Accounts.update_user_avatar(user, %{avatar: avatar_link}) do
          {:ok, _user} ->
            changeset = Accounts.change_user_avatar(%User{})
            {:noreply,
              socket
              |> assign(avatar_changeset: changeset)
              |> put_flash(:info, "User avatar updated successfully.")
              |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, avatar_changeset: changeset)}
        end
    end
  end

  def handle_event("validate_avatar", _params, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_avatar
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, avatar_changeset: changeset)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply,
      socket
      |> cancel_upload(:avatar, ref)
      |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))}
  end

  def handle_event("remove_avatar", _params, socket) do
    user = socket.assigns.active_user

    File.rm!("priv/static#{user.avatar}")

    case Accounts.update_user_avatar(user, %{avatar: nil}) do
      {:ok, _user} ->
        changeset = Accounts.change_user_avatar(%User{})
        {:noreply,
          socket
          |> assign(changeset: changeset)
          |> put_flash(:info, "User avatar removed successfully.")
          |> push_redirect(to: Routes.live_path(socket, __MODULE__, settings: 1))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
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
    cond do
      is_nil(socket.assigns.active_user) ->
        # User is not logged in
        push_redirect(socket, to: "/users/log_in")

      socket.assigns[:active_board_id] != board_id ->
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

      true ->
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
    |> assign(page_title: "404 Page Not Found")
  end

  defp registration_helper(socket) do
    socket
    |> assign(nav: :register)
    |> assign(page_title: "Register")
    |> assign(changeset: Accounts.change_user_registration(%User{}))
  end

  defp settings_helper(socket) do
    case socket.assigns.active_user do
      nil ->
        push_redirect(socket, to: "/users/log_in")
      user ->
        socket
        |> assign(nav: :settings)
        |> assign(page_title: "User Settings")
        |> assign(email_changeset: Accounts.change_user_email(user))
        |> assign(password_changeset: Accounts.change_user_password(user))
        |> assign(tz_changeset: Accounts.change_user_timezone(user))
        |> assign(title_changeset: Accounts.change_user_title(user))
        |> assign(avatar_changeset: Accounts.change_user_avatar(user))
    end
  end

  defp user_confirmation_helper(socket, token) do
    # Do not log in the user after confirmation to avoid a
    # leaked token giving the user access to the account.
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Account confirmed successfully.")
        |> redirect(to: "/users/log_in")

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{active_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(socket, to: "/")

          %{} ->
            socket
            |> put_flash(:error, "Account confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end

  defp email_update_helper(socket, token) do
    case Accounts.update_user_email(socket.assigns.active_user, token) do
      :ok ->
        socket
        |> put_flash(:info, "Email changed successfully.")
        |> push_redirect(to: Routes.live_path(socket, __MODULE__))

      :error ->
        socket
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> push_redirect(to: Routes.live_path(socket, __MODULE__))
    end
  end
end
