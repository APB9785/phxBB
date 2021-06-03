defmodule PhxBbWeb.UserCache do
  @moduledoc """
  Functions for building and updating the user cache.
  """

  alias PhxBb.Accounts
  alias PhxBb.Accounts.User
  alias PhxBb.Boards.Board

  def cache_self(%User{} = user) do
    %{
      name: user.username,
      joined: user.inserted_at,
      title: user.title,
      avatar: user.avatar,
      post_count: user.post_count
    }
  end

  def from_post_list(post_list, cache) do
    post_list
    |> Enum.reduce([], fn p, acc -> [p.last_user | [p.author | acc]] end)
    |> build(cache)
  end

  def from_topic(post, replies, cache) do
    parse_ids_from_topic(post, replies)
    |> build(cache)
  end

  def from_board_list(board_list, cache) do
    Enum.reduce(board_list, [], &check_last_user/2)
    |> build(cache)
  end

  def single_user(%User{id: id}, cache), do: build([id], cache)
  def single_user(id, cache) when is_integer(id), do: build([id], cache)

  defp check_last_user(%Board{last_user: nil}, prev_ids), do: prev_ids
  defp check_last_user(%Board{last_user: id}, prev_ids), do: [id | prev_ids]

  defp parse_ids_from_topic(post, replies) do
    # reply_ids = Enum.reduce(replies, [], &parse_single_post/2)
    # parse_single_post(post, reply_ids)
    Enum.reduce(replies, [], &parse_single_post/2)
    |> then(&parse_single_post(post, &1))
  end

  defp parse_single_post(post, prev_ids) do
    case post.edited_by do
      nil -> [post.author | prev_ids]
      editor -> [post.author | [editor | prev_ids]]
    end
  end

  # Leverages Map.put_new_lazy/3 to check every ID but only run the query
  # for previously unseen IDs
  defp build(user_ids, cache) when is_list(user_ids) do
    Enum.reduce(user_ids, cache, fn id, acc ->
      fun = fn -> Accounts.get_user_for_cache(id) end
      Map.put_new_lazy(acc, id, fun)
    end)
  end
end
