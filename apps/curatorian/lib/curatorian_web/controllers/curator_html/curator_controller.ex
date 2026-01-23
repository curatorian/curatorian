defmodule CuratorianWeb.CuratorController do
  use CuratorianWeb, :controller

  alias Voile.Schema.Accounts

  def index(conn, params) do
    # Always filter to show only verified users in public list
    params = Map.put(params, "status_filter", "verified")
    {users, total_pages, total_count} = Accounts.list_users_paginated(1, 10, params)
    pagination = %{users: users, total_pages: total_pages, total_count: total_count}

    conn
    |> assign(:curatorians, pagination.users)
    |> assign(:page, 1)
    |> assign(:total_pages, pagination.total_pages)
    |> assign(:page_title, "Lihat semua Kurator!")
    |> render(:index)
  end
end
