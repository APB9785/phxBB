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

alias PhxBb.Repo
alias PhxBb.Boards.Board

%Board{
  name: "General Discussion",
  description: "Test Board #1",
  post_count: 0,
  topic_count: 0,
  last_post: nil,
  last_user: nil
}
|> Repo.insert!()

%Board{
  name: "Ontopic Discussion",
  description: "Test Board #2",
  post_count: 0,
  topic_count: 0,
  last_post: nil,
  last_user: nil
}
|> Repo.insert!()
