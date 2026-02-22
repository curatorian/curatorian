defmodule CuratorianWeb.Router do
  use CuratorianWeb, :router

  # Note: For LiveView sessions that need authentication, use VoileWeb.UserAuth's
  # on_mount callbacks directly in the live_session definition:
  #
  #   live_session :authenticated, on_mount: [{VoileWeb.UserAuth, :require_authenticated}] do
  #     live "/dashboard", DashboardLive, :index
  #   end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CuratorianWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CuratorianWeb.UserAuth
    plug CuratorianWeb.Plugs.CrossAppCookie
    plug CuratorianWeb.Plugs.GetCurrentPath
  end

  pipeline :dashboard do
    plug :browser
    plug :put_layout, html: {CuratorianWeb.Layouts, :dashboard}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :internal_api do
    plug :accepts, ["json"]
    plug Curatorian.Plugs.InternalApiAuth
  end

  scope "/", CuratorianWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
  end

  # Internal API for cross-server authentication (Atrium -> Curatorian)
  # Used when Curatorian and Atrium are on different servers
  scope "/api/internal", CuratorianWeb do
    pipe_through :internal_api
    post "/auth/token", InternalAuthController, :issue_token
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:curatorian, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CuratorianWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
