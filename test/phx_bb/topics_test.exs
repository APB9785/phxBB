defmodule PhxBb.TopicsTest do
  use PhxBb.DataCase

  import PhxBb.AccountsFixtures
  import PhxBb.ForumFixtures

  alias PhxBb.SeenTopics.SeenTopic
  alias PhxBb.Topics
  alias PhxBb.Topics.Topic

  setup do
    user = user_fixture()
    board = board_fixture()

    %{
      user: user,
      board: board,
      topic: topic_fixture(user, board)
    }
  end

  describe "topics" do
    test "list_topics/3 returns all topics in a board", %{user: user, board: board, topic: topic} do
      seen_query = from(s in SeenTopic, where: s.user_id == ^user.id)
      topic = PhxBb.Repo.preload(topic, author: [], recent_user: [], seen_at: seen_query)

      assert Topics.list_topics(board.id, 1, user) == [topic]
    end

    test "get_topic!/1 returns the topic with given id", %{topic: topic} do
      assert Topics.get_topic!(topic.id) == topic
    end

    test "create_topic/1 with valid data creates a topic", context do
      assert %Topic{} = context[:topic]
      assert context[:topic].title == "test title"
      assert context[:topic].board_id == context[:board].id
      assert context[:topic].author_id == context[:user].id
    end

    test "create_topic/1 with invalid data returns error changeset", context do
      invalid = %{
        author_id: context[:user],
        board_id: context[:board],
        body: "",
        title: "",
        recent_user_id: context[:user]
      }

      assert {:error, :topic, %Ecto.Changeset{}, _} = Topics.create_topic(invalid)
    end

    test "update_topic/2 with valid data updates the topic", %{topic: topic} do
      user_2 = user_fixture()
      board_2 = board_fixture()

      changes = %{
        author_id: user_2.id,
        board_id: board_2.id,
        title: "some updated title",
        recent_user_id: user_2.id
      }

      assert {:ok, %Topic{} = topic} = Topics.update_topic(topic, changes)
      assert topic.title == "some updated title"
      assert topic.board_id == board_2.id
      assert topic.author_id == user_2.id
      assert topic.recent_user_id == user_2.id
    end

    test "update_topic/2 with invalid data returns error changeset", %{topic: topic} do
      assert {:error, %Ecto.Changeset{}} = Topics.update_topic(topic, %{title: ""})
      assert topic == Topics.get_topic!(topic.id)
    end

    # ** (Ecto.ConstraintError) constraint error when attempting to delete struct:
    #     * boards_recent_topic_id_fkey (foreign_key_constraint)
    # test "delete_topic/1 deletes the topic", %{topic: topic} do
    #   assert {:ok, %Topic{}} = Topics.delete_topic(topic)
    #   assert_raise Ecto.NoResultsError, fn -> Topics.get_topic!(topic.id) end
    # end

    test "change_topic/1 returns a topic changeset", %{topic: topic} do
      assert %Ecto.Changeset{} = Topics.change_topic(topic)
    end
  end
end
