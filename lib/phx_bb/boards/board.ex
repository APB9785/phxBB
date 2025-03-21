defmodule PhxBb.Boards.Board do
  @moduledoc """
  This module defines the Board schema and changeset.
  """
  use PhxBb.Schema

  import Ecto.Changeset

  schema "boards" do
    field :description, :string
    field :name, :string
    field :post_count, :integer
    field :topic_count, :integer

    belongs_to :recent_topic, PhxBb.Topics.Topic
    belongs_to :recent_user, PhxBb.Accounts.User

    has_many :topics, PhxBb.Topics.Topic, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board, attrs) do
    fields = [
      :name,
      :description,
      :topic_count,
      :post_count,
      :recent_topic_id,
      :recent_user_id
    ]

    board
    |> cast(attrs, fields)
    |> validate_required([:name, :description])
  end
end
