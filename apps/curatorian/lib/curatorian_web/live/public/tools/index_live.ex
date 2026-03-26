defmodule CuratorianWeb.Public.Tools.IndexLive do
  use CuratorianWeb, :live_view

  @tools [
    %{
      id: "library",
      title: "Perpustakaan",
      description: "Tools untuk sumber perpustakaan dan klasifikasi.",
      path: "/tools/library",
      status: "live"
    },
    %{
      id: "museum",
      title: "Museum",
      description: "Tools manajemen museum dan katalog pameran.",
      path: "/tools/museum",
      status: "soon"
    },
    %{
      id: "gallery",
      title: "Galeri",
      description: "Tools galeri untuk koleksi visual.",
      path: "/tools/gallery",
      status: "soon"
    },
    %{
      id: "archive",
      title: "Arsip",
      description: "Tools arsip untuk penyimpanan sumber daya.",
      path: "/tools/archive",
      status: "soon"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Alat Curatorian", tools: @tools)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto py-8 px-4">
        <h1 class="text-3xl sm:text-4xl font-bold mb-2">Pusat Tools Curatorian</h1>
        <p class="text-base text-base-content/70 mb-6">
          Jelajahi ekosistem Tools, dan akses modul yang telah siap atau yang akan datang.
        </p>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          <%= for tool <- @tools do %>
            <div id={"tool-card-#{tool.id}"}>
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
