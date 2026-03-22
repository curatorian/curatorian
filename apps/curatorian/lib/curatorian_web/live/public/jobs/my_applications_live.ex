defmodule CuratorianWeb.Public.Jobs.MyApplicationsLive do
  @moduledoc "Authenticated user application list (/jobs/my-applications)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    applications = Public.list_applications_by_user(user_id)

    postings_by_id =
      applications
      |> Enum.map(& &1.job_posting_id)
      |> Enum.uniq()
      |> Enum.map(fn id -> {id, Public.get_job_posting_by_id!(id)} end)
      |> Map.new()

    {:ok,
     socket
     |> assign(:page_title, "Riwayat Lamaran")
     |> assign(:applications, applications)
     |> assign(:postings_by_id, postings_by_id)}
  end

  defp application_status_label(:pending), do: "Baru"
  defp application_status_label(:reviewed), do: "Ditinjau"
  defp application_status_label(:shortlisted), do: "Shortlist"
  defp application_status_label(:rejected), do: "Ditolak"
  defp application_status_label(:hired), do: "Diterima"
  defp application_status_label(_), do: "-"

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto py-8 px-4">
        <h1 class="text-3xl font-semibold text-base-content mb-3">Riwayat Lamaran</h1>
        <p class="text-base-content/60 mb-6">Lihat status lamaran yang Anda kirimkan.</p>

        <div class="space-y-4">
          <div :if={@applications == []} class="p-8 text-center border border-base-300 rounded-2xl">
            Anda belum mengajukan lamaran ke lowongan manapun.
          </div>

          <div
            :for={application <- @applications}
            class="bg-base-100 border border-base-300 rounded-2xl p-4"
          >
            <div class="flex flex-col md:flex-row justify-between gap-3">
              <div>
                <p class="font-semibold text-base-content">
                  <.link
                    navigate={~p"/jobs/#{@postings_by_id[application.job_posting_id].slug}"}
                    class="hover:text-primary"
                  >
                    {@postings_by_id[application.job_posting_id].title}
                  </.link>
                </p>
                <p class="text-sm text-base-content/70">
                  {@postings_by_id[application.job_posting_id].institution_name}
                </p>
              </div>

              <div class="text-sm">
                <span class="inline-flex items-center rounded-full bg-base-200 text-base-content px-3 py-1">
                  {application_status_label(application.status)}
                </span>
                <p class="mt-1 text-base-content/60 text-xs">
                  Dikirim pada {DateTime.to_date(application.applied_at) |> Date.to_string()}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
