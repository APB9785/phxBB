defmodule PhxBb.RepliesTest do
  use PhxBb.DataCase

  import PhxBb.AccountsFixtures
  import PhxBb.ForumFixtures

  alias PhxBb.Replies

  describe "replies" do
    alias PhxBb.Replies.Reply

    @invalid_attrs %{post_id: nil, author: nil, body: nil}


    test "list_replies/1 returns all replies for a post" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      reply = reply_fixture(%{post_id: post.id, author: user.id})

      assert Replies.list_replies(post.id) == [reply]
    end

    test "get_reply!/1 returns the reply with given id" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      reply = reply_fixture(%{post_id: post.id, author: user.id})

      assert Replies.get_reply!(reply.id) == reply
    end

    test "create_reply/1 with valid data creates a reply" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      reply = reply_fixture(%{post_id: post.id, author: user.id})

      assert %Reply{} = reply
      assert reply.author == user.id
      assert reply.body == "some body"
      assert reply.post_id == post.id
    end

    test "create_reply/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Replies.create_reply(@invalid_attrs)
    end

    test "update_reply/2 with valid data updates the reply" do
      board = board_fixture()
      user = user_fixture()
      user_2 = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      post_2 = post_fixture(%{author: user.id, board_id: board.id})
      reply = reply_fixture(%{post_id: post.id, author: user.id})

      assert {:ok, %Reply{} = reply} =
        Replies.update_reply(reply, %{author: user_2.id, post_id: post_2.id, body: "some updated body"})
      assert reply.author == user_2.id
      assert reply.body == "some updated body"
      assert reply.post_id == post_2.id
    end

    test "update_reply/2 with invalid data returns error changeset" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      reply = reply_fixture(%{post_id: post.id, author: user.id})

      assert {:error, %Ecto.Changeset{}} = Replies.update_reply(reply, @invalid_attrs)
      assert reply == Replies.get_reply!(reply.id)
    end

    test "delete_reply/1 deletes the reply" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      reply = reply_fixture(%{post_id: post.id, author: user.id})

      assert {:ok, %Reply{}} = Replies.delete_reply(reply)
      assert_raise Ecto.NoResultsError, fn -> Replies.get_reply!(reply.id) end
    end

    test "change_reply/1 returns a reply changeset" do
      board = board_fixture()
      user = user_fixture()
      post = post_fixture(%{author: user.id, board_id: board.id})
      reply = reply_fixture(%{post_id: post.id, author: user.id})

      assert %Ecto.Changeset{} = Replies.change_reply(reply)
    end
  end
end
