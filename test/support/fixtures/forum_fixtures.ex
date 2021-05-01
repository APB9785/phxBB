defmodule PhxBb.ForumFixtures do
  @moduledoc """
  This module contains functions for creating test replies, posts, and boards.
  """

  def reply_fixture(attrs \\ %{}) do
    {:ok, reply} =
      attrs
      |> Enum.into(%{body: "some body"})
      |> PhxBb.Replies.create_reply()

    reply
  end

  # def post_fixture(attrs \\ %{}) do
  #   {:ok, post} =
  #     attrs
  #     |> Enum.into(%{board_id: 1, body: "some body", title: "some title", reply_count: 0, view_count: 0})
  #     |> PhxBb.Posts.create_post()
  #
  #   post
  # end

  def board_fixture(attrs \\ %{}) do
    {:ok, board} =
      attrs
      |> Enum.into(%{name: "some name", description: "some description"})
      |> PhxBb.Boards.create_board()

    board
  end
end
