defmodule PhxBb.SeenTopics.SeenTopic do
  @moduledoc """
  Schema for SeenTopic.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "seen_topics" do
    field :time, :naive_datetime

    belongs_to :topic, PhxBb.Topics.Topic
    belongs_to :user, PhxBb.Accounts.User
  end

  @doc false
  def changeset(seen_topic, attrs) do
    seen_topic
    |> cast(attrs, [:time, :topic_id, :user_id])
    |> validate_required([:time, :topic_id, :user_id])
  end
end
