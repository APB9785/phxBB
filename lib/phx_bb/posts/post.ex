defmodule PhxBb.Posts.Post do
  @moduledoc """
  This module defines the Post schema and changeset.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "posts" do
    field :author, :integer
    field :body, :string
    field :title, :string
    field :last_user, :integer
    field :view_count, :integer
    field :reply_count, :integer
    has_many :replies, PhxBb.Replies.Reply, on_delete: :delete_all
    belongs_to :board, PhxBb.Boards.Board

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :board_id, :author, :last_user, :view_count, :reply_count])
    |> validate_required([:title, :body, :board_id, :author, :view_count, :reply_count])
    |> validate_length(:title, min: 3)
    |> validate_length(:body, min: 3)
  end
end
