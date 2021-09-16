defmodule PhxBb.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false

  alias PhxBb.Boards.Board
  alias PhxBb.Repo
  alias PhxBb.Topics.Topic

  @doc """
  Returns the list of boards.

  ## Examples

      iex> list_boards()
      [%Board{}, ...]

  """
  def list_boards do
    Repo.all(from b in Board, order_by: [asc: b.id], preload: [:recent_topic, :recent_user])
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
  def get_board!(id), do: Repo.get!(Board, id) |> Repo.preload([:recent_topic, :recent_user])

  def get_board(id), do: Repo.get(Board, id) |> Repo.preload([:recent_topic, :recent_user])

  def get_board_with_topics(id), do: Repo.get(Board, id) |> Repo.preload(:topics)

  @doc """
  Creates a board.

  ## Examples

      iex> create_board(%{field: value})
      {:ok, %Board{}}

      iex> create_board(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_board(attrs \\ %{}) do
    attrs =
      Map.merge(attrs, %{post_count: 0, topic_count: 0, recent_topic: nil, recent_user: nil})

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

  def added_topic(board_id, topic_id, user_id) do
    now = NaiveDateTime.utc_now()

    from(b in Board,
      update: [
        inc: [topic_count: 1, topic_count: 1],
        set: [recent_topic: ^topic_id, recent_user: ^user_id, updated_at: ^now]
      ],
      where: b.id == ^board_id
    )
    |> Repo.update_all([])
  end

  def added_post(board_id, topic_id, user_id) do
    now = NaiveDateTime.utc_now()

    from(b in Board,
      update: [
        inc: [topic_count: 1],
        set: [recent_topic: ^topic_id, recent_user: ^user_id, updated_at: ^now]
      ],
      where: b.id == ^board_id
    )
    |> Repo.update_all([])
  end

  def deleted_post(board_id) do
    from(b in Board,
      update: [inc: [topic_count: -1]],
      where: b.id == ^board_id
    )
    |> Repo.update_all([])
  end

  def deleted_latest_post(board_id, %Topic{
        id: topic_id,
        recent_user: recent_user,
        last_post_at: time
      }) do
    from(b in Board,
      update: [
        inc: [topic_count: -1],
        set: [recent_topic: ^topic_id, recent_user: ^recent_user, updated_at: ^time]
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
