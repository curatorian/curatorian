defmodule CuratorianWeb.CuratorController do
  use CuratorianWeb, :controller

  alias Curatorian.Accounts

  def index(conn, params) do
    pagination = Accounts.list_all_curatorian(params)

    conn
    |> assign(:curatorians, pagination.curatorians)
    |> assign(:page, pagination.page)
    |> assign(:total_pages, pagination.total_pages)
    |> assign(:page_title, "Lihat semua Kurator!")
    |> render(:index)
  end
end
