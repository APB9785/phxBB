defmodule PhxBb.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false

  alias PhxBb.Boards.Board
  alias PhxBb.Posts.Post
  alias PhxBb.Repo

  @doc """
  Returns the list of boards.

  ## Examples

      iex> list_boards()
      [%Board{}, ...]

  """
  def list_boards do
    Repo.all(from b in Board, order_by: [asc: b.id])
  end

  @doc """
  Gets a single board.

  Raises `Ecto.NoResultsError` if the Board does not exist.

  ## Examples

      iex> get_board!(123)
      %Board{}

      iex> get_board!(456)
      ** (Ecto.NoResultsError)

  """
  def get_board!(id), do: Repo.get!(Board, id)

  def get_board(id), do: Repo.get(Board, id)

  @doc """
  Creates a board.

  ## Examples

      iex> create_board(%{field: value})
      {:ok, %Board{}}

      iex> create_board(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_board(attrs \\ %{}) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a board.

  ## Examples

      iex> update_board(board, %{field: new_value})
      {:ok, %Board{}}

      iex> update_board(board, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Repo.update()
  end

  def added_post(board_id, post_id, user_id) do
    now = NaiveDateTime.utc_now()

    from(b in Board,
      update: [
        inc: [post_count: 1, topic_count: 1],
        set: [last_post: ^post_id, last_user: ^user_id, updated_at: ^now]
      ],
      where: b.id == ^board_id
    )
    |> Repo.update_all([])
  end

  def added_reply(board_id, post_id, user_id) do
    now = NaiveDateTime.utc_now()

    from(b in Board,
      update: [
        inc: [post_count: 1],
        set: [last_post: ^post_id, last_user: ^user_id, updated_at: ^now]
      ],
      where: b.id == ^board_id
    )
    |> Repo.update_all([])
  end

  def deleted_reply(board_id) do
    from(b in Board,
      update: [inc: [post_count: -1]],
      where: b.id == ^board_id
    )
    |> Repo.update_all([])
  end

  def deleted_latest_reply(board_id, %Post{id: post_id, last_user: last_user, last_reply_at: time}) do
    from(b in Board,
      update: [
        inc: [post_count: -1],
        set: [last_post: ^post_id, last_user: ^last_user, updated_at: ^time]
      ],
      where: b.id == ^board_id
    )
    |> Repo.update_all([])
  end

  @doc """
  Deletes a board.

  ## Examples

      iex> delete_board(board)
      {:ok, %Board{}}

      iex> delete_board(board)
      {:error, %Ecto.Changeset{}}

  """
  def delete_board(%Board{} = board) do
    Repo.delete(board)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking board changes.

  ## Examples

      iex> change_board(board)
      %Ecto.Changeset{data: %Board{}}

  """
  def change_board(%Board{} = board, attrs \\ %{}) do
    Board.changeset(board, attrs)
  end
end
