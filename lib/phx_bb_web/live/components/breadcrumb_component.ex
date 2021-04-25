defmodule PhxBbWeb.BreadcrumbComponent do
  @moduledoc """
  Breadcrumb
  """

  use PhxBbWeb, :live_component

  import PhxBbWeb.StyleHelpers

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end
end
