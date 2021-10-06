defmodule PhxBb.SeenTopicsTest do
  use PhxBb.DataCase

  import PhxBb.AccountsFixtures
  import PhxBb.ForumFixtures

  alias PhxBb.SeenTopics
  alias PhxBb.SeenTopics.SeenTopic

  setup do
    user = user_fixture()
    board = board_fixture()
    topic = topic_fixture(user, board)

    %{user: user, topic: topic}
  end

  describe "seen_topics" do
    @invalid_attrs %{seen_at: nil}

    test "list_seen_topics/0 returns all seen_topics", %{user: user, topic: topic} do
      seen_topic = seen_topic_fixture(user, topic)
      assert SeenTopics.list_seen_topics() == [seen_topic]
    end

    test "get_seen_topic!/1 returns the seen_topic with given id", %{user: user, topic: topic} do
      seen_topic = seen_topic_fixture(user, topic)
      assert SeenTopics.get_seen_topic!(seen_topic.id) == seen_topic
    end

    test "create_seen_topic/1 with valid data creates a seen_topic", %{user: user, topic: topic} do
      valid_attrs = %{user_id: user.id, topic_id: topic.id, seen_at: ~N[2021-10-05 20:05:00]}

      assert {:ok, %SeenTopic{} = seen_topic} = SeenTopics.create_seen_topic(valid_attrs)
      assert seen_topic.seen_at == ~N[2021-10-05 20:05:00]
    end

    test "create_seen_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SeenTopics.create_seen_topic(@invalid_attrs)
    end

    test "update_seen_topic/2 with valid data updates the seen_topic", %{user: user, topic: topic} do
      seen_topic = seen_topic_fixture(user, topic)
      update_attrs = %{seen_at: ~N[2021-10-06 20:05:00]}

      assert {:ok, %SeenTopic{} = seen_topic} =
               SeenTopics.update_seen_topic(seen_topic, update_attrs)

      assert seen_topic.seen_at == ~N[2021-10-06 20:05:00]
    end

    test "update_seen_topic/2 with invalid data returns error changeset", %{
      user: user,
      topic: topic
    } do
      seen_topic = seen_topic_fixture(user, topic)

      assert {:error, %Ecto.Changeset{}} =
               SeenTopics.update_seen_topic(seen_topic, @invalid_attrs)

      assert seen_topic == SeenTopics.get_seen_topic!(seen_topic.id)
    end

    test "delete_seen_topic/1 deletes the seen_topic", %{user: user, topic: topic} do
      seen_topic = seen_topic_fixture(user, topic)
      assert {:ok, %SeenTopic{}} = SeenTopics.delete_seen_topic(seen_topic)
      assert_raise Ecto.NoResultsError, fn -> SeenTopics.get_seen_topic!(seen_topic.id) end
    end

    test "change_seen_topic/1 returns a seen_topic changeset", %{user: user, topic: topic} do
      seen_topic = seen_topic_fixture(user, topic)
      assert %Ecto.Changeset{} = SeenTopics.change_seen_topic(seen_topic)
    end
  end
end
