defmodule PhxBb.ForumFixtures do
  @moduledoc """
  This module contains functions for creating test topics, posts, and boards.
  """

  alias PhxBb.{Boards, Messages, Posts, Topics}

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

  def seen_topic_fixture(user, topic, time \\ ~N[2021-10-05 20:05:00]) do
    attrs = %{user_id: user.id, topic_id: topic.id, time: time}
    {:ok, seen_topic} = PhxBb.SeenTopics.create_seen_topic(attrs)

    seen_topic
  end

  def message_fixture(sender, recipient, subject \\ "test subject", body \\ "test message") do
    attrs = %{"recipient_id" => recipient.id, "subject" => subject, "body" => body}
    {:ok, message} = Messages.create_message(attrs, sender.id)

    message
  end
end
