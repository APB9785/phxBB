defmodule PhxBb.Topics.NewTopic do
  @moduledoc """
  This module defines an embedded schema and changeset for new topic creation.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :title, :string
    field :body, :string
  end

  def changeset(new_topic, attrs) do
    new_topic
    |> cast(attrs, [:title, :body])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 3)
    |> validate_length(:body, min: 3)
  end
end
