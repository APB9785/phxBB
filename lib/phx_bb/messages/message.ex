defmodule PhxBb.Messages.Message do
  @moduledoc """
  This module defines the Message schema and changeset.
  """
  use PhxBb.Schema

  import Ecto.Changeset

  schema "messages" do
    field :subject, :string
    field :body, :string
    field :sent_at, :utc_datetime
    field :read_at, :utc_datetime

    belongs_to :author, PhxBb.Accounts.User
    belongs_to :recipient, PhxBb.Accounts.User
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:subject, :body, :author_id, :recipient_id, :sent_at, :read_at])
    |> validate_required([:subject, :body, :author_id, :recipient_id, :sent_at])
    |> validate_length(:body, min: 3)
    |> validate_length(:subject, min: 2)
  end
end
