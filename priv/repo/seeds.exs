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

gen_script =
  "This board is for discussion of a general nature. Please feel free to " <>
  "talk about your favorite interests. Anyone can post here as long as " <>
  "they are a registered user."

%Board{
  name: "General Discussion",
  description: gen_script,
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

custard =
  "All discussion of custard goes here. No custard posts will be allowed " <>
  "in other boards."

%Board{
  name: "Custard Discussion",
  description: custard,
  post_count: 0,
  topic_count: 0,
  last_post: nil,
  last_user: nil
}
|> Repo.insert!()
