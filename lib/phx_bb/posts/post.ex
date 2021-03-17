defmodule PhxBb.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :author, :integer
    field :body, :string
    field :title, :string
    field :last_user, :integer
    has_many :replies, PhxBb.Replies.Reply, on_delete: :delete_all
    belongs_to :board, PhxBb.Boards.Board

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :board_id, :author, :last_user])
    |> validate_required([:title, :body, :board_id, :author])
  end
end
