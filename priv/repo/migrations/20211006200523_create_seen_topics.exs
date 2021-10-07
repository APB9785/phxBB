defmodule PhxBb.Repo.Migrations.CreateSeenTopics do
  use Ecto.Migration

  def change do
    create table(:seen_topics) do
      add :time, :naive_datetime
      add :user_id, references(:users, on_delete: :delete_all)
      add :topic_id, references(:topics, on_delete: :delete_all)
    end

    create index(:seen_topics, [:user_id])
    create index(:seen_topics, [:topic_id])
  end
end
