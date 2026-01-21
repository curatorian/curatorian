defmodule CuratorianWeb.DashboardComponents do
  use Phoenix.Component
  use Phoenix.LiveComponent
  use Gettext, backend: CuratorianWeb.Gettext

  import CuratorianWeb.CoreComponents

  @doc """
  Stat Cards for Dashboard with Icons
  """
  attr :icon, :string, default: "hero-home-solid"
  attr :number, :integer, default: 0
  attr :title, :string, default: "Title"
  attr :bg_color, :string, default: "bg-violet-100"
  attr :icon_color, :string, default: "text-violet-500"

  def stat_cards(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-500 rounded-lg p-5 flex items-center justify-start gap-6">
      <div class={"p-2 rounded-full #{@bg_color}"}>
        <.icon name={@icon} class={"h-10 w-10 #{@icon_color}"} />
      </div>

      <div>
        <h3>{@number}</h3>

        <p class="text-sm">{@title}</p>
      </div>
    </div>
    """
  end
end
