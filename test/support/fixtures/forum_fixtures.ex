defmodule PhxBb.ForumFixtures do
  @moduledoc """
  This module contains functions for creating test replies, posts, and boards.
  """

  def reply_fixture(attrs \\ %{}) do
    {:ok, reply} =
      Map.merge(%{body: "some body"}, attrs)
      |> PhxBb.Replies.create_reply()

    reply
  end

  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      Map.merge(
        %{
          board_id: 1,
          body: "some body",
          title: "some title",
          reply_count: 0,
          view_count: 0
        },
        attrs
      )
      |> PhxBb.Posts.create_post()

    post
  end

  def board_fixture(attrs \\ %{}) do
    {:ok, board} =
      Map.merge(%{name: "some name", description: "some description"}, attrs)
      |> PhxBb.Boards.create_board()

    board
  end
end
