defmodule PhxBb.BoardsTest do
  use PhxBb.DataCase

  import PhxBb.ForumFixtures

  alias PhxBb.Boards
  alias PhxBb.Boards.Board

  @valid_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup do
    board = board_fixture() |> PhxBb.Repo.preload([:recent_topic, :recent_user])
    %{board: board}
  end

  describe "boards" do
    test "list_boards/0 returns all boards", %{board: board} do
      assert Boards.list_boards() == [board]
    end

    test "get_board!/1 returns the board with given id", %{board: board} do
      assert Boards.get_board!(board.id) == board
    end

    test "create_board/1 with valid data creates a board" do
      assert {:ok, %Board{} = board} = Boards.create_board(@valid_attrs)
      assert board.name == "some name"
      assert board.description == "some description"
    end

    test "create_board/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Boards.create_board(@invalid_attrs)
    end

    test "update_board/2 with valid data updates the board", %{board: board} do
      assert {:ok, %Board{} = board} = Boards.update_board(board, @update_attrs)
      assert board.name == "some updated name"
      assert board.description == "some updated description"
    end

    test "update_board/2 with invalid data returns error changeset", %{board: board} do
      assert {:error, %Ecto.Changeset{}} = Boards.update_board(board, @invalid_attrs)
      assert board == Boards.get_board!(board.id)
    end

    test "delete_board/1 deletes the board", %{board: board} do
      assert {:ok, %Board{}} = Boards.delete_board(board)
      assert_raise Ecto.NoResultsError, fn -> Boards.get_board!(board.id) end
    end

    test "change_board/1 returns a board changeset", %{board: board} do
      assert %Ecto.Changeset{} = Boards.change_board(board)
    end
  end
end
