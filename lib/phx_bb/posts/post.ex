defmodule PhxBb.Posts.Post do
  @moduledoc """
  This module defines the Reply schema and changeset.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "posts" do
    field :body, :string

    belongs_to :author, PhxBb.Accounts.User
    belongs_to :edited_by, PhxBb.Accounts.User
    belongs_to :topic, PhxBb.Topics.Topic

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :author_id, :topic_id, :edited_by_id])
    |> validate_required([:body, :author_id, :topic_id])
    |> validate_length(:body, min: 3)
  end
end
