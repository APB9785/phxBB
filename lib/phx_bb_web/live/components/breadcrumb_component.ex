defmodule PhxBbWeb.BreadcrumbComponent do
  @moduledoc """
  Breadcrumb
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.StyleHelpers

  def render(assigns) do
    ~L"""
    <div class="pt-4 pb-4 md:pl-8 md:pt-8" id="breadcrumb">
       >
      <%= live_patch "Board Index",
            to: Routes.live_path(@socket, PhxBbWeb.PageLive),
            class: link_style(@active_user),
            id: "crumb-index" %>
      <%= if @nav in [:post, :create_post] do %>
       >
      <%= live_patch @active_board.name,
            to: Routes.live_path(@socket, PhxBbWeb.PageLive, board: @active_board.id),
            class: link_style(@active_user),
            id: "crumb-board" %>
      <% end %>
    </div>
    """
  end
end
