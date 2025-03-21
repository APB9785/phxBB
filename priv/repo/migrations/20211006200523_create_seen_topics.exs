defmodule PhxBb.Repo.Migrations.CreateSeenTopics do
  use Ecto.Migration

  def change do
    create table(:seen_topics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :time, :utc_datetime
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :topic_id, references(:topics, type: :binary_id, on_delete: :delete_all)
    end

    create index(:seen_topics, [:user_id])
    create index(:seen_topics, [:topic_id])
  end
end
