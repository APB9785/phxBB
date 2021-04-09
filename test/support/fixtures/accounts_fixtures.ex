defmodule PhxBb.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PhxBb.Accounts` context.
  """

  def unique_user, do: "user#{rem(System.unique_integer([:positive, :monotonic]), 1000000000)}"
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    unique_username = unique_user()

    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password(),
        username: unique_username,
        post_count: 0
      })
      |> PhxBb.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
