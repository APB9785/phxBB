defmodule PhxBb.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias PhxBb.Repo

  alias PhxBb.Posts.Post

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts(board_id)
      [%Post{}, ...]

  """
  def list_posts(board_id) do
    Repo.all(from p in Post,
             where: p.board_id == ^board_id)
    |> Enum.sort_by(fn schema -> schema.updated_at end, {:desc, NaiveDateTime})
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
  def get_post!(id), do: Repo.get!(Post, id)

  def get_title(id) do
    Repo.one from p in Post,
               where: p.id == ^id,
               select: p.title
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:view_count, 0)
      |> Map.put(:reply_count, 0)

    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
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
    |> Repo.update([force: true])
  end

  def viewed(post_id) do
    from(p in Post, update: [inc: [view_count: 1]], where: p.id == ^post_id)
    |> Repo.update_all([])
  end

  def added_reply(post_id, user_id) do
    now = NaiveDateTime.utc_now()
    from(p in Post,
      update: [inc: [reply_count: 1],
               set: [last_user: ^user_id, updated_at: ^now]],
      where: p.id == ^post_id)
    |> Repo.update_all([])
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

  def delete_post_by_id(id) do
    id
    |> get_post!
    |> delete_post
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
