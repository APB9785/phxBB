defmodule PhxBb.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :body, :string
      add :subject, :string
      add :author_id, references(:users)
      add :recipient_id, references(:users)

      add :sent_at, :naive_datetime
      add :read_at, :naive_datetime
    end

    create index(:messages, [:author_id])
    create index(:messages, [:recipient_id])
  end
end
