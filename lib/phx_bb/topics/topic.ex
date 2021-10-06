defmodule PhxBb.Topics.Topic do
  @moduledoc """
  This module defines the Topic schema and changeset.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "topics" do
    field :last_post_at, :naive_datetime
    field :post_count, :integer
    field :title, :string
    field :view_count, :integer

    has_many :posts, PhxBb.Posts.Post, on_delete: :delete_all

    belongs_to :author, PhxBb.Accounts.User
    belongs_to :board, PhxBb.Boards.Board
    belongs_to :recent_user, PhxBb.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(
      attrs,
      [
        :title,
        :board_id,
        :author_id,
        :recent_user_id,
        :view_count,
        :post_count,
        :last_post_at
      ]
    )
    |> validate_required([:title, :board_id, :author_id, :view_count, :post_count])
    |> validate_length(:title, min: 3)
  end
end
