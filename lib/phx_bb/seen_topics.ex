defmodule PhxBb.SeenTopics do
  @moduledoc """
  The SeenTopics context.
  """

  import Ecto.Query, warn: false

  alias PhxBb.Repo
  alias PhxBb.SeenTopics.SeenTopic

  @doc """
  Returns the SeenTopic struct for the given User and Topic, if it exists.
  Otherwise returns nil.

  ## Examples

      iex> get_seen_topic(%User{}, %Topic{})
      %SeenTopic{}

      iex> get_seen_topic(%User{}, %Topic{id: "bad_id"})
      nil

  """
  def get_seen_topic(user_id, topic_id) do
    Repo.one(
      from SeenTopic,
        where: [user_id: ^user_id, topic_id: ^topic_id]
    )
  end

  @doc """
  Gets a single seen_topic.

  Raises `Ecto.NoResultsError` if the Seen topic does not exist.

  ## Examples

      iex> get_seen_topic!(123)
      %SeenTopic{}

      iex> get_seen_topic!(456)
      ** (Ecto.NoResultsError)

  """
  def get_seen_topic!(id), do: Repo.get!(SeenTopic, id)

  @doc """
  Creates a seen_topic.

  ## Examples

      iex> create_seen_topic(%{field: value})
      {:ok, %SeenTopic{}}

      iex> create_seen_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_seen_topic(attrs \\ %{}) do
    %SeenTopic{}
    |> SeenTopic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a seen_topic.

  ## Examples

      iex> update_seen_topic(seen_topic, %{field: new_value})
      {:ok, %SeenTopic{}}

      iex> update_seen_topic(seen_topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_seen_topic(%SeenTopic{} = seen_topic, attrs) do
    seen_topic
    |> SeenTopic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a seen_topic.

  ## Examples

      iex> delete_seen_topic(seen_topic)
      {:ok, %SeenTopic{}}

      iex> delete_seen_topic(seen_topic)
      {:error, %Ecto.Changeset{}}

  """
  def delete_seen_topic(%SeenTopic{} = seen_topic) do
    Repo.delete(seen_topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking seen_topic changes.

  ## Examples

      iex> change_seen_topic(seen_topic)
      %Ecto.Changeset{data: %SeenTopic{}}

  """
  def change_seen_topic(%SeenTopic{} = seen_topic, attrs \\ %{}) do
    SeenTopic.changeset(seen_topic, attrs)
  end

  @doc """
  Updates the database to record that the User with given user_id has just seen
  the Topic with given topic_id. Has no effect if the user_id is nil.

  ## Examples

      iex> seen_now(123, 456)
      {:ok, %SeenTopic{}}

      iex> seen_now(nil, 456)
      :ok

  """
  def seen_now(nil, _topic), do: :ok

  def seen_now(user_id, topic_id) do
    now = DateTime.utc_now()

    case get_seen_topic(user_id, topic_id) do
      %SeenTopic{} = seen_topic ->
        update_seen_topic(seen_topic, %{time: now})

      nil ->
        create_seen_topic(%{user_id: user_id, topic_id: topic_id, time: now})
    end
  end
end
