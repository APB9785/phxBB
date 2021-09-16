defmodule PhxBb.PostsTest do
  use PhxBb.DataCase

  import PhxBb.AccountsFixtures
  import PhxBb.ForumFixtures

  alias PhxBb.Posts
  alias PhxBb.Posts.Post

  setup do
    user = user_fixture()
    board = board_fixture()
    topic = topic_fixture(user, board) |> PhxBb.Repo.preload([:posts])
    [post] = topic.posts
    post = PhxBb.Repo.preload(post, [:author, :edited_by])

    %{user: user, board: board, topic: topic, post: post}
  end

  describe "posts" do
    test "list_posts/1 returns all posts for a post", %{topic: topic, post: post} do
      assert Posts.list_posts(topic.id) == [post]
    end

    test "get_post!/1 returns the post with given id", %{post: post} do
      assert Posts.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post", %{user: user, topic: topic, post: post} do
      assert %Post{} = post
      assert post.author_id == user.id
      assert post.body == "test body"
      assert post.topic_id == topic.id
    end

    test "create_post/1 with invalid data returns error changeset", %{user: user, topic: topic} do
      invalid = %{topic_id: topic.id, author_id: user.id, body: ""}
      assert {:error, :post, %Ecto.Changeset{}, _} = Posts.create_post(invalid)
    end

    test "update_post/2 with valid data updates the post", %{user: user, board: board, post: post} do
      user_2 = user_fixture()
      topic_2 = topic_fixture(user, board)

      assert {:ok, %Post{} = post} =
               Posts.update_post(post, %{
                 author_id: user_2.id,
                 topic_id: topic_2.id,
                 body: "some updated body"
               })

      assert post.author_id == user_2.id
      assert post.body == "some updated body"
      assert post.topic_id == topic_2.id
    end

    test "update_post/2 with invalid data returns error changeset", %{post: post} do
      invalid = %{topic_id: nil, author_id: nil, body: nil}
      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, invalid)
      assert post == Posts.get_post!(post.id)
    end

    test "delete_post/1 deletes the post", %{post: post} do
      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset", %{post: post} do
      assert %Ecto.Changeset{} = Posts.change_post(post)
    end
  end
end
