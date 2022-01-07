defmodule PhxBb.Messages do
  @moduledoc """
  The Messages context
  """
  import Ecto.Query, warn: false

  alias PhxBb.Messages.Message
  alias PhxBb.Repo

  @doc """
  Returns a user's inbox.

  ## Examples

      iex> for_user(user_id)
      [%Message{}, ...]

  """
  def for_user(user_id) do
    Repo.all(
      from Message,
        where: [recipient_id: ^user_id],
        order_by: [desc: :sent_at],
        preload: [:author]
    )
  end

  @doc """
  Returns the unread message count for a given user id.

  ## Examples

      iex> unread_for_user(user_id)
      3

  """
  def unread_for_user(user_id) do
    Repo.one(
      from m in Message,
        where: m.recipient_id == ^user_id,
        where: is_nil(m.read_at),
        select: count()
    )
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value}, author_id)
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value}, author_id)
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs, author_id) do
    now = NaiveDateTime.utc_now()

    attrs =
      attrs
      |> Map.put("author_id", author_id)
      |> Map.put("sent_at", now)

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks a message as read by its recipient.

  ## Examples

      iex> mark_read(message_id)
      {:ok, %Message{}}

  """
  def mark_read(message_id) do
    now = NaiveDateTime.utc_now()
    message = Repo.one(from Message, where: [id: ^message_id])

    {:ok, message} = update_message(message, %{read_at: now})

    {:ok, Repo.preload(message, :author)}
  end

  @doc """
  Marks a message as unread by its recipient.

  ## Examples

      iex> mark_unread(message_id)
      {:ok, %Message{}}

  """
  def mark_unread(message_id) do
    message = Repo.one(from Message, where: [id: ^message_id])

    {:ok, message} = update_message(message, %{read_at: nil})

    {:ok, Repo.preload(message, :author)}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking board changes.

  ## Examples

      iex> change_board(board)
      %Ecto.Changeset{data: %Board{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  @doc """
  Returns the last message sent by a given user.  This is currently used for
  integration testing so we can store the ID of a message after it is created.
  """
  def last_message_sent(author_id) do
    Repo.one(
      from Message,
        where: [author_id: ^author_id],
        order_by: [desc: :sent_at],
        limit: 1
    )
  end
end
