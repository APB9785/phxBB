defmodule PhxBb.SeenTopics do
  @moduledoc """
  The SeenTopics context.
  """

  import Ecto.Query, warn: false
  alias PhxBb.Repo

  alias PhxBb.SeenTopics.SeenTopic

  @doc """
  Returns the list of seen_topics.

  ## Examples

      iex> list_seen_topics()
      [%SeenTopic{}, ...]

  """
  def list_seen_topics do
    Repo.all(SeenTopic)
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
end
