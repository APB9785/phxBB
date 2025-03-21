defmodule PhxBb.Repo.Migrations.CreateForum do
  use Ecto.Migration

  def change do
    create table(:boards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :topic_count, :integer
      add :post_count, :integer
      add :recent_user_id, references(:users, type: :binary_id)

      timestamps()
    end

    create table(:topics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :author_id, references(:users, type: :binary_id)
      add :board_id, references(:boards, type: :binary_id, on_delete: :delete_all)
      add :recent_user_id, references(:users, type: :binary_id)
      add :last_post_at, :utc_datetime
      add :view_count, :integer
      add :post_count, :integer

      timestamps()
    end

    create index(:topics, [:board_id])

    alter table(:boards) do
      add :recent_topic_id, references(:topics, type: :binary_id)
    end

    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :text
      add :author_id, references(:users, type: :binary_id)
      add :topic_id, references(:topics, type: :binary_id, on_delete: :delete_all)
      add :edited_by_id, references(:users, type: :binary_id)

      timestamps()
    end

    create index(:posts, [:topic_id])
  end
end
