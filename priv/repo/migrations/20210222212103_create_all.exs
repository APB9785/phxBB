defmodule PhxBb.Repo.Migrations.CreateAll do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :disabled_at, :naive_datetime
      add :username, :citext, null: false
      add :post_count, :integer
      add :timezone, :string
      add :title, :string
      add :avatar, :string
      add :theme, :string
      add :admin, :boolean
      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:boards) do
      add :name, :string
      add :description, :string
      add :topic_count, :integer
      add :post_count, :integer
      add :last_user, references(:users)

      timestamps()
    end

    create table(:posts) do
      add :title, :string
      add :body, :text
      add :author, references(:users)
      add :board_id, references(:boards, on_delete: :delete_all)
      add :last_user, references(:users)
      add :last_reply_at, :naive_datetime
      add :view_count, :integer
      add :reply_count, :integer
      add :edited_by, references(:users)

      timestamps()
    end

    create index(:posts, [:board_id])

    alter table(:boards) do
      add :last_post, references(:posts)
    end

    create table(:replies) do
      add :body, :text
      add :author, references(:users)
      add :post_id, references(:posts, on_delete: :delete_all)
      add :edited_by, references(:users)

      timestamps()
    end

    create index(:replies, [:post_id])
  end
end
