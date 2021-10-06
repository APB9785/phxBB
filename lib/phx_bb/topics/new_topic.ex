defmodule PhxBb.Topics.NewTopic do
  @moduledoc """
  This module defines an embedded schema and changeset for new topic creation.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :body, :string
    field :title, :string
  end

  def changeset(new_topic, attrs) do
    new_topic
    |> cast(attrs, [:body, :title])
    |> validate_required([:body, :title])
    |> validate_length(:title, min: 3)
    |> validate_length(:body, min: 3)
  end
end
