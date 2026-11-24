defmodule CuratorianWeb.Public.EbookReaderLive do
  @moduledoc """
  Full-page e-book reader for readable collection attachments (PDF/EPUB).

  Access is gated: only confirmed, atrium-connected users may stream the
  bytes, and they flow exclusively through `/ebooks/:id/stream` so the raw
  storage URL never reaches the browser DOM.

  Above the reading surface sits a metadata card built from the collection
  and its Dublin Core fields (title, institution, subject, language, etc.).
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @impl true
  def mount(%{"attachment_id" => attachment_id} = _params, _session, socket) do
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    cond do
      is_nil(current_user) ->
        {:ok,
         socket
         |> put_flash(:error, "Silakan masuk ke akun Anda untuk membaca e-book.")
         |> push_navigate(to: ~p"/login")}

      not Public.profile_connected?(current_user.id) ->
        {:ok,
         socket
         |> put_flash(
           :error,
           "Hanya pengguna terverifikasi yang dapat membaca e-book. Hubungkan profil Anda ke Atrium terlebih dahulu."
         )
         |> push_navigate(to: ~p"/collections")}

      true ->
        attachment = Public.get_public_attachment(attachment_id)
        collection = attachment && Public.get_public_collection(attachment.attachable_id)

        if attachment && collection do
          fields = index_fields(collection.collection_fields)

          {:ok,
           socket
           |> assign(:attachment, attachment)
           |> assign(:collection, collection)
           |> assign(:org_context, Public.get_org_context_for_node(collection.unit_id))
           |> assign(:fields, fields)
           |> assign(:file_kind, kind(attachment))
           |> assign(:file_url, Public.asset_url(attachment.file_path))
           |> assign(:page, 1)
           |> assign(:total_pages, nil)
           |> assign(:progress, 0)}
        else
          {:ok,
           socket
           |> put_flash(:error, "Koleksi tidak tersedia.")
           |> push_navigate(to: ~p"/collections")}
        end
    end
  end

  # Index the collection's Dublin Core fields by name so the metadata card
  # can look them up: %{"title" => "...", "dc:subject" => "...", ...}.
  defp index_fields(collection_fields) do
    collection_fields
    |> Enum.reject(fn f -> is_nil(f.value) or f.value == "" end)
    |> Enum.into(%{}, fn f ->
      {normalize_field_name(f.name || ""), f.value}
    end)
  end

  defp normalize_field_name(name) do
    name
    |> String.downcase()
    |> String.replace_prefix("dc:", "")
  end

  defp kind(%{mime_type: "application/pdf"}), do: :pdf
  defp kind(_), do: :unsupported

  # Progress reports from the reader hook: page N of total T.
  @impl true
  def handle_event("reader_progress", %{"page" => page, "total" => total}, socket) do
    page = to_int(page)
    total = to_int(total)
    progress = if (total && total > 0) and page, do: min(100, round(page * 100 / total)), else: 0

    {:noreply,
     socket
     |> assign(:page, page || 1)
     |> assign(:total_pages, total)
     |> assign(:progress, progress)}
  end

  def handle_event(_other, _params, socket), do: {:noreply, socket}

  defp to_int(v) when is_integer(v), do: v

  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp to_int(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} current_uri={@current_uri}>
      <div class="mx-auto max-w-5xl px-5 sm:px-6 lg:px-8 py-6">
        <div class="rounded-[var(--radius-box)] overflow-hidden border border-neutral-700 shadow-xl bg-neutral-800">
          <%!-- Card header: back link + file title + progress --%>
          <div class="flex items-center justify-between gap-3 px-4 py-2 bg-neutral-800">
            <div class="flex items-center gap-3 min-w-0">
              <.link
                navigate={~p"/collections/#{@collection.id}"}
                class="btn btn-ghost btn-sm text-neutral-300 hover:text-white gap-1.5 shrink-0"
              >
                <.icon name="hero-arrow-left" class="size-4" />
                <span class="hidden sm:inline">Kembali</span>
              </.link>
              <div class="min-w-0 border-l border-neutral-700 pl-3">
                <p class="text-sm font-medium text-neutral-100 truncate">
                  {@attachment.original_name}
                </p>
                <p class="text-xs text-neutral-400 truncate">{@collection.title}</p>
              </div>
            </div>

            <div class="flex items-center gap-2 shrink-0">
              <div class="hidden sm:flex items-center gap-2 text-xs text-neutral-400 tabular-nums">
                <span>{@page}{if @total_pages, do: " / #{@total_pages}", else: ""}</span>
              </div>
              <div class="w-24 sm:w-40 h-1.5 bg-neutral-700 rounded-full overflow-hidden">
                <div
                  class="h-full bg-primary rounded-full transition-all duration-300"
                  style={"width: #{@progress}%"}
                >
                </div>
              </div>
            </div>
          </div>

          <%!-- Collapsible metadata strip --%>
          <details class="group px-4 py-2 bg-neutral-800/60 border-y border-neutral-700/60">
            <summary class="flex items-center gap-2 cursor-pointer list-none text-sm text-neutral-300 hover:text-white">
              <.icon name="hero-information-circle" class="size-4 shrink-0" />
              <span class="font-medium truncate">{@collection.title}</span>
              <.icon
                name="hero-chevron-down"
                class="size-3.5 opacity-50 group-open:rotate-180 transition-transform shrink-0"
              />
            </summary>
            <dl class="grid grid-cols-2 md:grid-cols-4 gap-x-6 gap-y-2 mt-3 text-xs">
              <.meta_row label="Institusi" value={org_name(@org_context)} />
              <.meta_row label="Jenis" value={@collection.collection_type} />
              <.meta_row label="Subjek" value={@fields["subject"]} />
              <.meta_row label="Bahasa" value={@fields["language"]} />
              <.meta_row label="Pencipta" value={@fields["creator"]} />
              <.meta_row label="Penerbit" value={@fields["publisher"]} />
              <.meta_row label="Tanggal" value={@fields["date"]} />
              <.meta_row label="Format" value={@attachment.mime_type} />
            </dl>
          </details>

          <%!-- Reader surface: the hook renders pages into this element --%>
          <div
            id="ebook-reader"
            class="h-[70vh] bg-neutral-900 overflow-hidden"
            data-file-url={@file_url}
            data-stream-url={~p"/ebooks/#{@attachment.id}/stream"}
            data-kind={@file_kind}
            phx-hook="EBookReader"
            phx-update="ignore"
          >
            <div class="flex items-center justify-center h-full">
              <div class="text-center">
                <.icon
                  name="hero-book-open"
                  class="size-12 text-neutral-600 mx-auto mb-3 animate-pulse"
                />
                <p class="text-sm text-neutral-400">Memuat e-book...</p>
              </div>
            </div>
          </div>

          <%!-- Card footer toolbar: page navigation + zoom + hand --%>
          <div class="flex items-center justify-between gap-2 px-3 sm:px-4 py-2 bg-neutral-800 border-t border-neutral-700">
            <%!-- Page navigation --%>
            <div class="flex items-center gap-1">
              <button
                id="reader-page-prev"
                type="button"
                class="btn btn-ghost btn-sm text-neutral-300 hover:text-white hover:bg-neutral-700 gap-1"
                aria-label="Halaman sebelumnya"
              >
                <.icon name="hero-chevron-left" class="size-4" />
                <span class="hidden sm:inline text-xs">Sebelumnya</span>
              </button>
              <button
                id="reader-page-next"
                type="button"
                class="btn btn-ghost btn-sm text-neutral-300 hover:text-white hover:bg-neutral-700 gap-1"
                aria-label="Halaman berikutnya"
              >
                <span class="hidden sm:inline text-xs">Selanjutnya</span>
                <.icon name="hero-chevron-right" class="size-4" />
              </button>
            </div>

            <div class="flex-1" />

            <%!-- Zoom + hand (PDF only) --%>
            <div class="flex items-center gap-1">
              <button
                id="reader-zoom-out"
                type="button"
                class={[
                  "btn btn-ghost btn-sm text-neutral-300 hover:text-white hover:bg-neutral-700",
                  @file_kind != :pdf && "invisible"
                ]}
                aria-label="Perkecil"
              >
                <.icon name="hero-magnifying-glass-minus" class="size-4" />
              </button>
              <span
                id="reader-zoom-label"
                class={[
                  "text-xs text-neutral-400 tabular-nums w-11 text-center hidden sm:inline",
                  @file_kind != :pdf && "invisible"
                ]}
              >
                100%
              </span>
              <button
                id="reader-zoom-in"
                type="button"
                class={[
                  "btn btn-ghost btn-sm text-neutral-300 hover:text-white hover:bg-neutral-700",
                  @file_kind != :pdf && "invisible"
                ]}
                aria-label="Perbesar"
              >
                <.icon name="hero-magnifying-glass-plus" class="size-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def org_name(nil), do: nil

  def org_name(%{node_profile: np}) when np != nil,
    do: np.institution_name || np.name

  def org_name(_), do: nil

  attr :label, :string, required: true
  attr :value, :string, default: nil

  def meta_row(assigns) do
    ~H"""
    <div class="flex gap-1.5">
      <dt class="text-neutral-500 shrink-0">{@label}:</dt>
      <dd class="text-neutral-200 truncate">{@value}</dd>
    </div>
    """
  end
end
