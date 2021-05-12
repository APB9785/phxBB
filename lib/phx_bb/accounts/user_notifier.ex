defmodule PhxBb.Accounts.UserNotifier do
  @moduledoc """
  For simplicity, this module simply logs messages to the terminal.
  You should replace it by a proper email or notification tool, such as:

    * Swoosh - https://hexdocs.pm/swoosh
    * Bamboo - https://hexdocs.pm/bamboo
  """

  import Swoosh.Email

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    body =
      greeting(user) <>
        "You can confirm your account by visiting the URL below:\n\n" <>
        url <> create_ignore()

    new()
    |> to({user.username, user.email})
    |> from({"PhxBB team", "phxbbmail@gmail.com"})
    |> subject("Please confirm your phxBB acount")
    |> text_body(body)
    |> PhxBb.Mailer.deliver()

    # Returns for LiveView testing
    return_token(url)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    body =
      greeting(user) <>
        "You can reset your password by visiting the URL below:\n\n" <>
        url <> change_ignore()

    new()
    |> to({user.username, user.email})
    |> from({"PhxBB team", "phxbbmail@gmail.com"})
    |> subject("Reset password for your phxBB acount")
    |> text_body(body)
    |> PhxBb.Mailer.deliver()

    # Returns for controller testing
    body
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    body =
      greeting(user) <>
        "You can confirm your updated email by visiting the URL below:\n\n" <>
        url <> change_ignore()

    new()
    |> to({user.username, user.email})
    |> from({"PhxBB team", "phxbbmail@gmail.com"})
    |> subject("Change the email for your phxBB acount")
    |> text_body(body)
    |> PhxBb.Mailer.deliver()

    # Returns for LiveView testing
    return_token(url)
  end

  defp greeting(user), do: "Hi #{user.username},\n\n"

  defp change_ignore, do: "\n\nIf you didn't request this change, please ignore this."

  defp create_ignore, do: "\n\nIf you didn't create an account with us, please ignore this.\n"

  defp return_token(url) do
    [_, token] = String.split(url, "=")
    token
  end
end
