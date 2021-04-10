defmodule PhxBb.Replies.Reply do
  @moduledoc """
  This module defines the Reply schema and changeset.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "replies" do
    field :author, :integer
    field :body, :string
    belongs_to :post, PhxBb.Posts.Post

    timestamps()
  end

  @doc false
  def changeset(reply, attrs) do
    reply
    |> cast(attrs, [:body, :author, :post_id])
    |> validate_required([:body, :author, :post_id])
  end
end
