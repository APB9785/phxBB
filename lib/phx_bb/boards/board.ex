defmodule PhxBb.Boards.Board do
  @moduledoc """
  This module defines the Board schema and changeset.
  """

  use Ecto.Schema
  
  import Ecto.Changeset

  schema "boards" do
    field :description, :string
    field :name, :string
    field :topic_count, :integer
    field :post_count, :integer
    field :last_post, :integer
    field :last_user, :integer

    timestamps()
  end

  @doc false
  def changeset(board, attrs) do
    fields =
      [
        :name, :description, :topic_count, :post_count,
        :last_post, :last_user
      ]

    board
    |> cast(attrs, fields)
    |> validate_required([:name, :description])
  end
end
