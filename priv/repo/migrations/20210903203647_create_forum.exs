defmodule PhxBb.Repo.Migrations.CreateForum do
  use Ecto.Migration

  def change do
    create table(:boards) do
      add :name, :string
      add :description, :string
      add :topic_count, :integer
      add :post_count, :integer
      add :recent_user_id, references(:users)

      timestamps()
    end

    create table(:topics) do
      add :title, :string
      add :author_id, references(:users)
      add :board_id, references(:boards, on_delete: :delete_all)
      add :recent_user_id, references(:users)
      add :last_post_at, :naive_datetime
      add :view_count, :integer
      add :post_count, :integer

      timestamps()
    end

    create index(:topics, [:board_id])

    alter table(:boards) do
      add :recent_topic_id, references(:topics)
    end

    create table(:posts) do
      add :body, :text
      add :author_id, references(:users)
      add :topic_id, references(:topics, on_delete: :delete_all)
      add :edited_by_id, references(:users)

      timestamps()
    end

    create index(:posts, [:topic_id])
  end
end
