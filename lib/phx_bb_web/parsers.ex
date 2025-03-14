defmodule PhxBbWeb.Parsers do
  @moduledoc """
  Functions for parsing text to be displayed.
  """

  def parse_post_body(content) do
    content
    |> Earmark.as_html!()
    |> PhoenixHtmlSanitizer.Helpers.sanitize(:markdown_html)
  end

  def shortener(text) do
    case String.slice(text, 0..45) do
      ^text -> text
      short -> [short, "..."]
    end
  end
end
