defmodule PhxBb.ForumFixtures do
  @moduledoc """
  This module contains functions for creating test topics, posts, and boards.
  """

  alias PhxBb.{Boards, Posts, Topics}

  def post_fixture(user, topic, body \\ "some body") do
    attrs = %{body: body, author_id: user.id, topic_id: topic.id}
    {:ok, post} = Posts.create_post(attrs)

    post
  end

  def topic_fixture(user, board, title \\ "test title", body \\ "test body") do
    attrs = %{
      body: body,
      title: title,
      board_id: board.id,
      author_id: user.id,
      recent_user_id: user.id
    }

    {:ok, topic} = Topics.create_topic(attrs)

    topic
  end

  def board_fixture(name \\ "some name", description \\ "some description") do
    {:ok, board} = Boards.create_board(%{name: name, description: description})

    board
  end
end
