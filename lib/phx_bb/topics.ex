defmodule PhxBb.Topics do
  @moduledoc """
  The Topics context.
  """

  import Ecto.Query, warn: false

  alias PhxBb.Accounts.User
  alias PhxBb.Boards.Board
  alias PhxBb.Posts.Post
  alias PhxBb.Repo
  alias PhxBb.SeenTopics
  alias PhxBb.SeenTopics.SeenTopic
  alias PhxBb.Topics.{NewTopic, Topic}

  @doc """
  Returns the list of topics.

  ## Examples

      iex> list_topics(board_id)
      [%Topic{}, ...]

  """
  def list_topics(board_id, page, user) do
    seen_query = seen_query(user)

    Repo.all(
      from Topic,
        where: [board_id: ^board_id],
        offset: ^((page - 1) * 5),
        limit: 5,
        order_by: [{:desc, :last_post_at}],
        preload: [author: [], recent_user: [], seen_at: ^seen_query]
    )
  end

  defp seen_query(nil), do: from(s in SeenTopic, where: is_nil(s.user_id))
  defp seen_query(user), do: from(s in SeenTopic, where: s.user_id == ^user.id)

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
    |> Ecto.Multi.run(:seen, fn _repo, %{topic: topic} ->
      SeenTopics.seen_now(user_id, topic.id)
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

  # @doc """
  # Deletes a topic.  Currently unused - when implemented will require handling
  # of cases where the topic is currently associated with a board as the most
  # recent topic.
  #
  # ## Examples
  #
  #     iex> delete_topic(topic)
  #     {:ok, %Topic{}}
  #
  #     iex> delete_topic(topic)
  #     {:error, %Ecto.Changeset{}}
  #
  # """
  # def delete_topic(%Topic{} = topic) do
  #   Repo.delete(topic)
  # end

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

  def up_to_date?(%Topic{seen_at: []}), do: false

  def up_to_date?(%Topic{seen_at: [%SeenTopic{time: seen}], last_post_at: latest}) do
    NaiveDateTime.compare(seen, latest) != :lt
  end
end
