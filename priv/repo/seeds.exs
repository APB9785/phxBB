# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PhxBb.Repo.insert!(%PhxBb.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PhxBb.Accounts
alias PhxBb.Accounts.User
alias PhxBb.Boards.Board
alias PhxBb.Repo

board_base = %Board{
  name: nil,
  description: nil,
  post_count: 0,
  topic_count: 0,
  last_post: nil,
  last_user: nil
}

# Create Administrator Account

{:ok, admin_user} =
  %{
    email: "admin@phxbb.app",
    password: "CHANGEME",
    username: "admin",
    post_count: 9000,
    title: "Forum Administrator",
    theme: "dark",
    admin: true,
    timezone: "US/Central"
  }
  |> Accounts.register_user()

User.confirm_changeset(admin_user)
|> Repo.update!()

# Board names/descriptions

%{
  board_base
  | name: "General Discussion",
    description:
      "This board is for discussion of a general nature. Please feel free to talk about your favorite interests."
}
|> Repo.insert!()

%{
  board_base
  | name: "phxBB Discussion",
    description: "All questions and comments related to phxBB should be made here."
}
|> Repo.insert!()

%{
  board_base
  | name: "Elixir/Phoenix Discussion",
    description: "Anything related to Elixir or Phoenix should be posted here."
}
|> Repo.insert!()
