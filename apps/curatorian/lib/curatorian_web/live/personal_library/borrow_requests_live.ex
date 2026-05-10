defmodule CuratorianWeb.PersonalLibrary.BorrowRequestsLive do
  @moduledoc "Authenticated borrow request dashboard for Curatorian users."

  use CuratorianWeb, :live_view

  alias Curatorian.PersonalLibrary

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope && socket.assigns.current_scope.user

    if user do
      borrow_requests = PersonalLibrary.list_borrow_requests_for_borrower(user.id)

      incoming_requests =
        PersonalLibrary.list_borrow_requests_for_lender(user.id, status: "pending")

      {:ok,
       socket
       |> assign(:page_title, "Borrow Requests")
       |> assign(:borrow_requests, borrow_requests)
       |> assign(:incoming_requests, incoming_requests)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be logged in to view borrow requests.")
       |> push_navigate(to: "/login")}
    end
  end

  @impl true
  def handle_event("approve_request", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user

    with %{} = request <- PersonalLibrary.get_borrow_request(id),
         true <- request.lender_user_id == user.id,
         {:ok, _request} <- PersonalLibrary.change_borrow_request_status(request, "approved") do
      refresh_requests(socket)
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Unable to approve borrow request.")}
    end
  end

  def handle_event("decline_request", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user

    with %{} = request <- PersonalLibrary.get_borrow_request(id),
         true <- request.lender_user_id == user.id,
         {:ok, _request} <- PersonalLibrary.change_borrow_request_status(request, "declined") do
      refresh_requests(socket)
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Unable to decline borrow request.")}
    end
  end

  defp refresh_requests(socket) do
    user = socket.assigns.current_scope.user
    borrow_requests = PersonalLibrary.list_borrow_requests_for_borrower(user.id)

    incoming_requests =
      PersonalLibrary.list_borrow_requests_for_lender(user.id, status: "pending")

    {:noreply,
     socket
     |> assign(:borrow_requests, borrow_requests)
     |> assign(:incoming_requests, incoming_requests)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto py-10 px-4 sm:px-6 lg:px-8">
        <div class="mb-6 flex items-center justify-between gap-4">
          <div>
            <h1 class="text-2xl font-semibold">{gettext("Borrow Requests")}</h1>
            <p class="text-sm text-base-content/60">
              {gettext(
                "Request book loans from personal library collections or manage incoming requests."
              )}
            </p>
          </div>
        </div>

        <div class="grid gap-6 lg:grid-cols-2">
          <div class="rounded-[var(--radius-box)] border border-base-300/60 bg-base-100 p-5">
            <h2 class="text-lg font-semibold mb-4">{gettext("Outgoing Requests")}</h2>
            <%= if @borrow_requests == [] do %>
              <p class="text-sm text-base-content/60">{gettext("No borrow requests yet.")}</p>
            <% else %>
              <ul class="space-y-3">
                <li
                  :for={request <- @borrow_requests}
                  class="rounded-3xl border border-base-300/60 bg-base-200 p-4"
                >
                  <p class="font-medium">{request.item_title}</p>
                  <p class="text-sm text-base-content/60">{gettext("Status")}: {request.status}</p>
                  <p class="text-sm text-base-content/60">{request.request_message || ""}</p>
                </li>
              </ul>
            <% end %>
          </div>

          <div class="rounded-[var(--radius-box)] border border-base-300/60 bg-base-100 p-5">
            <h2 class="text-lg font-semibold mb-4">{gettext("Incoming Requests")}</h2>
            <%= if @incoming_requests == [] do %>
              <p class="text-sm text-base-content/60">
                {gettext("No incoming requests at the moment.")}
              </p>
            <% else %>
              <ul class="space-y-3">
                <li
                  :for={request <- @incoming_requests}
                  class="rounded-3xl border border-base-300/60 bg-base-200 p-4"
                >
                  <p class="font-medium">{request.item_title}</p>
                  <p class="text-sm text-base-content/60">
                    {gettext("Borrower")}: {request.borrower_user_id}
                  </p>
                  <p class="text-sm text-base-content/60">{request.request_message || ""}</p>
                  <div class="mt-3 flex flex-wrap gap-2">
                    <button
                      phx-click="approve_request"
                      phx-value-id={request.id}
                      class="btn btn-sm btn-success"
                    >
                      {gettext("Approve")}
                    </button>
                    <button
                      phx-click="decline_request"
                      phx-value-id={request.id}
                      class="btn btn-sm btn-ghost border-error text-error"
                    >
                      {gettext("Decline")}
                    </button>
                  </div>
                </li>
              </ul>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
