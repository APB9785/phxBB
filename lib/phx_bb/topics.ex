defmodule PhxBb.Topics do
  @moduledoc """
  The Topics context.
  """

  import Ecto.Query, warn: false

  alias PhxBb.Accounts.User
  alias PhxBb.Boards.Board
  alias PhxBb.Posts.Post
  alias PhxBb.Repo
  alias PhxBb.Topics.{NewTopic, Topic}

  @doc """
  Returns the list of topics.

  ## Examples

      iex> list_topics(board_id)
      [%Topic{}, ...]

  """
  def list_topics(board_id, page) do
    Repo.all(
      from Topic,
        where: [board_id: ^board_id],
        offset: ^((page - 1) * 5),
        limit: 5,
        order_by: [{:desc, :last_post_at}],
        preload: [:author, :recent_user]
    )
  end

  def most_recent_topic(board_id) do
    Repo.all(
      from t in Topic,
        where: t.board_id == ^board_id,
        order_by: [desc: t.last_post_at],
        limit: 1
    )
    |> hd
  end

  @doc """
  Gets a single topic.

  Raises nil if the Topic does not exist.

  ## Examples

      iex> get_topic(123)
      %Topic{}

      iex> get_topic(456)
      nil

  """
  def get_topic(id) do
    case Repo.get(Topic, id) do
      nil -> nil
      topic -> Repo.preload(topic, [:board, [posts: [:author, :edited_by]]])
    end
  end

  def get_topic!(id), do: Repo.get!(Topic, id)

  # def get_title(id) do
  #   Repo.one(
  #     from t in Topic,
  #       where: t.id == ^id,
  #       select: t.title
  #   )
  # end

  @doc """
  Creates a topic.

  ## Examples

      iex> create_topic(%{field: value})
      {:ok, %Topic{}}

      iex> create_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_topic(attrs \\ %{}) do
    now = NaiveDateTime.utc_now()
    user_id = attrs.author_id
    board_id = attrs.board_id
    {body, attrs} = Map.pop(attrs, :body)
    attrs = Map.merge(attrs, %{view_count: 0, post_count: 1, last_post_at: now})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:topic, Topic.changeset(%Topic{}, attrs))
    |> Ecto.Multi.update_all(
      :board,
      fn %{topic: topic} ->
        from(Board,
          where: [id: ^board_id],
          update: [
            inc: [topic_count: 1, post_count: 1],
            set: [recent_topic_id: ^topic.id, recent_user_id: ^user_id, updated_at: ^now]
          ]
        )
      end,
      []
    )
    |> Ecto.Multi.insert(:post, fn %{topic: topic} ->
      Post.changeset(%Post{}, %{body: body, author_id: user_id, topic_id: topic.id})
    end)
    |> Ecto.Multi.update_all(:user, from(User, where: [id: ^user_id]), inc: [post_count: +1])
    |> Repo.transaction()
    |> case do
      {:ok, %{topic: topic}} ->
        Phoenix.PubSub.broadcast(PhxBb.PubSub, "board:#{board_id}", {:new_topic, topic.id})
        {:ok, topic}

      {:error, operation, value, changes} ->
        {:error, operation, value, changes}
    end
  end

  @doc """
  Updates a topic.

  ## Examples

      iex> update_topic(topic, %{field: new_value})
      {:ok, %Topic{}}

      iex> update_topic(topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  def increment_view_count(topic_id) do
    from(Topic, where: [id: ^topic_id])
    |> Repo.update_all(inc: [view_count: 1])
  end

  def deleted_post(topic_id) do
    from(Topic, where: [id: ^topic_id])
    |> Repo.update_all(inc: [post_count: -1])
  end

  def deleted_last_post(topic_id, user_id, time) do
    from(t in Topic,
      update: [inc: [post_count: -1], set: [last_user: ^user_id, last_post_at: ^time]],
      where: t.id == ^topic_id
    )
    |> Repo.update_all([])
  end

  def deleted_only_post(%Topic{id: id, author: author, inserted_at: time}) do
    from(t in Topic,
      update: [inc: [post_count: -1], set: [last_user: ^author, last_post_at: ^time]],
      where: t.id == ^id
    )
    |> Repo.update_all([])
  end

  @doc """
  Deletes a topic.

  ## Examples

      iex> delete_topic(topic)
      {:ok, %Topic{}}

      iex> delete_topic(topic)
      {:error, %Ecto.Changeset{}}

  """
  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.

  ## Examples

      iex> change_topic(topic)
      %Ecto.Changeset{data: %Topic{}}

  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  def new_topic_changeset(%NewTopic{} = new_topic, attrs \\ %{}) do
    NewTopic.changeset(new_topic, attrs)
  end
end