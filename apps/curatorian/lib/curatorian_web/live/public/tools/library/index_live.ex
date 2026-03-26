defmodule CuratorianWeb.Public.Tools.Library.IndexLive do
  use CuratorianWeb, :live_view

  @tools [
    %{
      id: "classification",
      title: "Klasifikasi Perpustakaan",
      description: "Telusuri DDC/UDC/LCC.",
      path: "/tools/library/classifications",
      status: "live"
    },
    %{
      id: "metadata",
      title: "Asisten Metadata",
      description: "Manajemen metadata perpustakaan (segera hadir).",
      path: "#",
      status: "soon"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Tools Perpustakaan", tools: @tools)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto py-8 px-4">
        <div class="mb-6">
          <h1 class="text-3xl sm:text-4xl font-bold">Perpustakaan</h1>
          <p class="text-base text-base-content/70">
            Fitur perpustakaan yang telah selesai dan roadmap modul yang akan datang.
          </p>
          <.link navigate="/tools" class="text-sm text-primary hover:underline">
            ← Kembali ke Pusat Alat
          </.link>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <%= for tool <- @tools do %>
            <div id={"library-tool-#{tool.id}"}>
              <.tool_card tool={tool} />
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp tool_card(assigns) do
    ~H"""
    <article class="bg-base-100 border border-base-300 rounded-2xl shadow-sm hover:shadow-md transition overflow-hidden h-full">
      <div class="p-5 flex flex-col h-full">
        <div class="mb-4">
          <h3 class="text-lg font-semibold">{@tool.title}</h3>
          <p class="text-sm text-base-content/70 mt-1">{@tool.description}</p>
        </div>

        <div class="mt-auto">
          <%= if @tool.status == "soon" do %>
            <div class="inline-flex items-center gap-2 rounded-full bg-base-200 px-4 py-2 text-xs font-semibold text-base-content/80">
              <.icon name="hero-clock" class="w-4 h-4" /> Akan Datang
            </div>
          <% else %>
            <.link
              navigate={@tool.path}
              class="inline-flex items-center gap-2 rounded-full border border-primary px-4 py-2 text-sm font-semibold text-primary transition"
            >
              <.icon name="hero-arrow-right" class="w-4 h-4" /> Buka
            </.link>
          <% end %>
        </div>
      </div>
    </article>
    """
  end
end
