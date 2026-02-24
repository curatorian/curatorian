defmodule CuratorianWeb.Router do
  use CuratorianWeb, :router

  # ---------------------------------------------------------------------------
  # Pipelines
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # Public routes (no auth required)
  # ---------------------------------------------------------------------------

  scope "/", CuratorianWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
  end

  # Session controller handles form POST from login/register LiveViews
  scope "/", CuratorianWeb do
    pipe_through :browser

    post "/users/log_in", UserSessionController, :create
    delete "/users/log_out", UserSessionController, :delete
  end

  # Auth LiveViews — mounts scope but does NOT require authentication.
  # Logged-in users are redirected away inside mount/3.
  scope "/", CuratorianWeb do
    pipe_through :browser

    live_session :unauthenticated_only,
      on_mount: [{CuratorianWeb.UserAuth, :mount_current_scope}] do
      live "/login", UserLoginLive, :new
      live "/register", UserRegistrationLive, :new
    end
  end

  # ---------------------------------------------------------------------------
  # Authenticated routes — require a logged-in user
  # ---------------------------------------------------------------------------

  # Example authenticated section — expand as features are built:
  #
  #   scope "/", CuratorianWeb do
  #     pipe_through :browser
  #
  #     live_session :authenticated,
  #       on_mount: [{CuratorianWeb.UserAuth, :require_authenticated}] do
  #       live "/dashboard", DashboardLive, :index
  #     end
  #   end

  # ---------------------------------------------------------------------------
  # Internal API — cross-server auth for Atrium
  # ---------------------------------------------------------------------------

  scope "/api/internal", CuratorianWeb do
    pipe_through :internal_api
    post "/auth/token", InternalAuthController, :issue_token
  end

  # ---------------------------------------------------------------------------
  # Dev-only routes
  # ---------------------------------------------------------------------------

  if Application.compile_env(:curatorian, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CuratorianWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
