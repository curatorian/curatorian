defmodule CuratorianWeb.Router do
  use CuratorianWeb, :router

  import CuratorianWeb.UserAuth
  # import CuratorianWeb.UserAuthGoogle, only: [fetch_google_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CuratorianWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug CuratorianWeb.Plugs.GetCurrentPath
  end

  pipeline :dashboard do
    plug :browser
    plug :put_layout, html: {GlammWeb.Layouts, :dashboard}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CuratorianWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/kurator", CuratorController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", CuratorianWeb do
  #   pipe_through :api
  # end

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

  ## Authentication routes

  scope "/", CuratorianWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{CuratorianWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/login", MemberLoginLive, :new
      live "/users/register", UserRegistrationLive, :new
      # live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
    end

    post "/users/log_in", UserSessionController, :create
    live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

    live "/users/reset_password/:token", UserResetPasswordLive, :edit
  end

  scope "/", CuratorianWeb do
    pipe_through [:dashboard, :require_authenticated_user]

    post "/trix-uploads", Utils.TrixUploadsController, :create
    delete "/trix-uploads", Utils.TrixUploadsController, :delete

    live_session :require_authenticated_user,
      on_mount: [
        {CuratorianWeb.Utils.SaveRequestUri, :save_request_uri},
        {CuratorianWeb.UserAuth, :ensure_authenticated}
      ] do
      scope "/dashboard" do
        live "/", DashboardLive, :show

        scope "/blog" do
          live "/", DashboardLive.BlogsLive.Index, :index
          live "/new", DashboardLive.BlogsLive.New, :new
          live "/:slug", DashboardLive.BlogsLive.Show, :show
          live "/:slug/edit", DashboardLive.BlogsLive.Edit, :edit
        end

        scope "/orgs" do
          live "/", DashboardLive.OrgsLive.Index, :index
        end
      end

      live "/users/settings", UserSettingsLive, :edit

      live "/comments", CommentLive.Index, :index
      live "/comments/new", CommentLive.Index, :new
      live "/comments/:id", CommentLive.Show, :show
      live "/comments/:id/edit", CommentLive.Show, :edit
    end

    live_session :require_manager_role,
      on_mount: [
        {CuratorianWeb.Utils.SaveRequestUri, :save_request_uri},
        {CuratorianWeb.UserAuth, :ensure_authenticated},
        {CuratorianWeb.UserAuth, :ensure_user_is_manager}
      ] do
      scope "/dashboard" do
        scope "/user_manager" do
          live "/", DashboardLive.UserManagerLive.Index, :index
          live "/:username", DashboardLive.UserManagerLive.Show, :show
          live "/:username/edit", DashboardLive.UserManagerLive.Edit, :edit
          live "/:username/delete", DashboardLive.UserManagerLive.Delete, :delete
        end
      end
    end
  end

  scope "/auth/google", CuratorianWeb do
    pipe_through [:browser]

    get "/", GoogleAuthController, :request
    get "/callback", GoogleAuthController, :callback
  end

  scope "/", CuratorianWeb do
    pipe_through [:browser]

    get "/:username", ProfileController, :index
    get "/:username/blog/:slug", ProfileController, :show_blog

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [
        {CuratorianWeb.UserAuth, :mount_current_user}
      ] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
