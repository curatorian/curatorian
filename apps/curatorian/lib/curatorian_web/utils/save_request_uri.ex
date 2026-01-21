defmodule CuratorianWeb.Utils.SaveRequestUri do
  def on_mount(:save_request_uri, _params, _session, socket) do
    socket =
      socket
      |> Phoenix.LiveView.attach_hook(
        :save_request_path,
        :handle_params,
        &save_request_path/3
      )

    {:cont, socket}
  end

  defp save_request_path(_params, url, socket) do
    {:cont, Phoenix.Component.assign(socket, :current_uri, URI.parse(url) |> Map.get(:path))}
  end
end
