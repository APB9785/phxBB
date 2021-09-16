defmodule PhxBb.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PhxBb.Accounts` context.
  """

  def unique_user, do: "user#{rem(System.unique_integer([:positive, :monotonic]), 1_000_000_000)}"
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      username: unique_user()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      Map.merge(
        %{
          email: unique_user_email(),
          password: valid_user_password(),
          username: unique_user(),
          post_count: 0,
          title: "Registered User",
          theme: "dark",
          admin: false,
          timezone: "Etc/UTC"
        },
        attrs
      )
      |> PhxBb.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
