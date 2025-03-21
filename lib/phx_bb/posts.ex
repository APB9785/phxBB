defmodule PhxBb.Posts do
  @moduledoc """
  The Posts context.
  """
  import Ecto.Query, warn: false

  alias PhxBb.Accounts.User
  alias PhxBb.Boards.Board
  alias PhxBb.Posts.Post
  alias PhxBb.Repo
  alias PhxBb.SeenTopics
  alias PhxBb.Topics.Topic

  @doc """
  Returns the sorted list of posts.

  ## Examples

      iex> list_posts(topic_id)
      [%Post{}, ...]

  """
  def list_posts(topic_id) do
    Repo.all(
      from Post,
        where: [topic_id: ^topic_id],
        order_by: [asc: :inserted_at],
        preload: [:author, :edited_by]
    )
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id),
    do: Repo.get!(Post, id) |> Repo.preload([:author, :edited_by])

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    now = DateTime.utc_now()
    user_id = attrs.author_id
    topic_id = attrs.topic_id
    # Including board_id in attrs is optional, but saves a DB hit when included
    board_id =
      case attrs[:board_id] do
        nil -> Repo.get!(Topic, topic_id) |> Map.fetch!(:board_id)
        id -> id
      end

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:post, Post.changeset(%Post{}, attrs))
    |> Ecto.Multi.update_all(:board, from(Board, where: [id: ^board_id]),
      inc: [post_count: 1],
      set: [recent_topic_id: topic_id, recent_user_id: user_id, updated_at: now]
    )
    |> Ecto.Multi.update_all(:topic, from(Topic, where: [id: ^topic_id]),
      inc: [post_count: 1],
      set: [recent_user_id: user_id, last_post_at: now]
    )
    |> Ecto.Multi.run(:seen, fn _, _ -> SeenTopics.seen_now(user_id, topic_id) end)
    |> Ecto.Multi.update_all(:user, from(User, where: [id: ^user_id]), inc: [post_count: +1])
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} ->
        post = PhxBb.Repo.preload(post, [:author, :edited_by])
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "topic:#{topic_id}", {:update_post_list, post})
        {:ok, post}

      {:error, operation, value, changes} ->
        {:error, operation, value, changes}
    end
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, post} ->
        post = PhxBb.Repo.preload(post, [:author, :edited_by], force: true)

        Phoenix.PubSub.broadcast(
          PhxBb.PubSub,
          "topic:#{post.topic_id}",
          {:update_post_list, post}
        )

        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end
end
