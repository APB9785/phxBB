defmodule PhxBb.PostsTest do
  use PhxBb.DataCase

  import PhxBb.AccountsFixtures
  import PhxBb.ForumFixtures

  alias PhxBb.Posts

  setup do
    %{user: user_fixture()}
  end

  describe "posts" do
    alias PhxBb.Posts.Post

    @invalid_attrs %{author: nil, board_id: nil, body: nil, title: nil, reply_count: nil, view_count: nil}

    test "list_posts/1 returns all posts in a board" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})

      assert Posts.list_posts(board.id) == [post]
    end

    test "get_post!/1 returns the post with given id" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})

      assert Posts.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})

      assert %Post{} = post
      assert post.body == "some body"
      assert post.title == "some title"
      assert post.board_id == board.id
      assert post.author == user.id
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      board = board_fixture()
      board_2 = board_fixture()
      user = user_fixture()
      user_2 = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      changes =
        %{
          author: user_2.id,
          board_id: board_2.id,
          body: "some updated body",
          title: "some updated title"
        }

      assert {:ok, %Post{} = post} = Posts.update_post(post, changes)
      assert post.body == "some updated body"
      assert post.title == "some updated title"
      assert post.board_id == board_2.id
      assert post.author == user_2.id
    end

    test "update_post/2 with invalid data returns error changeset" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})

      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, @invalid_attrs)
      assert post == Posts.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})

      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})

      assert %Ecto.Changeset{} = Posts.change_post(post)
    end
  end
end
