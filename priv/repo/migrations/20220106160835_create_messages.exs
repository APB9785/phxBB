defmodule PhxBb.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :string
      add :subject, :string
      add :author_id, references(:users, type: :binary_id)
      add :recipient_id, references(:users, type: :binary_id)

      add :sent_at, :utc_datetime
      add :read_at, :utc_datetime
    end

    create index(:messages, [:author_id])
    create index(:messages, [:recipient_id])
  end
end
