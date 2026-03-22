defmodule CuratorianWeb.Public.Jobs.ApplyLive do
  @moduledoc "Authenticated in-platform application form (/jobs/:slug/apply)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  def mount(%{"slug" => slug}, _session, socket) do
    posting = Public.get_job_posting_by_slug(slug)

    cond do
      posting == nil ->
        {:ok,
         socket |> put_flash(:error, "Lowongan tidak ditemukan") |> push_navigate(to: "/jobs")}

      posting.application_method != :in_platform ->
        {:ok,
         socket
         |> put_flash(:info, "Lamaran hanya via situs institusi")
         |> push_navigate(to: "/jobs/#{slug}")}

      posting.status != :active or posting.deleted_at ->
        {:ok,
         socket |> put_flash(:error, "Lowongan tidak tidak aktif") |> push_navigate(to: "/jobs")}

      true ->
        user_id = socket.assigns.current_scope.user.id

        if Public.get_application_by_user_and_posting(user_id, posting.id) do
          {:ok,
           socket
           |> put_flash(:info, "Anda sudah melamar pada lowongan ini")
           |> push_navigate(to: "/jobs/#{slug}")}
        else
          form = to_form(%{"cover_letter" => "", "cv_url" => ""}, as: :application)

          {:ok,
           socket
           |> assign(:page_title, "Lamar #{posting.title}")
           |> assign(:posting, posting)
           |> assign(:form, form)}
        end
    end
  end

  def handle_event("validate", %{"application" => params}, socket) do
    {:noreply, socket |> assign(:form, to_form(params, as: :application))}
  end

  def handle_event("apply", %{"application" => params}, socket) do
    user_id = socket.assigns.current_scope.user.id

    attrs = %{
      "job_posting_id" => socket.assigns.posting.id,
      "voile_user_id" => user_id,
      "cover_letter" => params["cover_letter"],
      "cv_url" => params["cv_url"],
      "status" => :pending
    }

    case Public.create_application(attrs) do
      {:ok, _application} ->
        {:noreply,
         socket
         |> put_flash(:success, "Lamaran berhasil dikirim")
         |> push_navigate(to: ~p"/jobs/#{socket.assigns.posting.slug}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :application))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto py-8 px-4">
        <.link
          navigate={~p"/jobs/#{@posting.slug}"}
          class="text-sm text-base-content/60 hover:text-base-content"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Kembali ke detail
        </.link>

        <div class="mt-4 bg-base-100 border border-base-300 rounded-2xl p-6">
          <h1 class="text-2xl font-semibold text-base-content mb-3">Lamar: {@posting.title}</h1>

          <.form for={@form} phx-change="validate" phx-submit="apply" class="space-y-4">
            <.input
              field={@form[:cover_letter]}
              type="textarea"
              label="Surat Lamaran (opsional)"
              placeholder="Tulis alasan singkat mengapa Anda cocok..."
              rows="5"
            />

            <.input
              field={@form[:cv_url]}
              type="text"
              label="URL CV / Resume"
              placeholder="https://..."
            />

            <.button type="submit" class="btn-primary w-full" phx-disable-with="Mengirim...">
              Lamar Sekarang
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
