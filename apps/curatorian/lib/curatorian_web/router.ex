defmodule CuratorianWeb.Router do
  use CuratorianWeb, :router

  import VoileWeb.UserAuth
  # import VoileWeb.UserAuthGoogle, only: [fetch_google_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CuratorianWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
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

    get "/orgs", OrgsController, :index
    get "/orgs/:slug", OrgsController, :show, as: :organization
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
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [
        {VoileWeb.UserAuth, :mount_current_scope}
      ] do
      live "/register", UserLive.Registration, :new
      live "/login", UserLive.Login, :new
      live "/login/:token", UserLive.Confirmation, :new
    end

    post "/login", UserSessionController, :create
    delete "/logout", UserSessionController, :delete
  end

  scope "/", CuratorianWeb do
    pipe_through [:dashboard, :require_authenticated_user]

    post "/trix-uploads", Utils.TrixUploadsController, :create
    delete "/trix-uploads", Utils.TrixUploadsController, :delete

    live_session :require_authenticated_user,
      on_mount: [
        {CuratorianWeb.Utils.SaveRequestUri, :save_request_uri},
        {VoileWeb.UserAuth, :require_authenticated}
      ] do
      scope "/dashboard" do
        live "/", DashboardLive, :show

        scope "/blog" do
          live "/", DashboardLive.BlogsLive.Index, :index
          live "/new", DashboardLive.BlogsLive.Form, :new
          live "/:slug", DashboardLive.BlogsLive.Show, :show
          live "/:slug/edit", DashboardLive.BlogsLive.Form, :edit
        end

        scope "/orgs" do
          live "/", DashboardLive.OrgsLive.Index, :index
          live "/new", DashboardLive.OrgsLive.New, :new
          live "/:slug", DashboardLive.OrgsLive.Show, :show
          live "/:slug/edit", DashboardLive.OrgsLive.Edit, :edit
        end
      end

      # live "/users/settings", UserSettingsLive, :edit
      # live "/users/settings/change_password", UserLive.UserChangePassword, :edit

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/comments", CommentLive.Index, :index
      live "/comments/new", CommentLive.Index, :new
      live "/comments/:id", CommentLive.Show, :show
      live "/comments/:id/edit", CommentLive.Show, :edit

      # Protected organization routes
      resources "/orgs", OrgsController,
        param: "slug",
        only: [:new, :create, :edit, :update, :delete]

      post "/orgs/:slug/join", OrgsController, :join
      post "/orgs/:slug/leave", OrgsController, :leave
    end

    post "/users/update-password", UserSessionController, :update_password

    # Super Admin Routes - RBAC Management
    live_session :require_super_admin,
      on_mount: [
        {CuratorianWeb.Utils.SaveRequestUri, :save_request_uri},
        {VoileWeb.UserAuth, :require_authenticated},
        {VoileWeb.UserAuth, {:require_permission, "system.settings"}}
      ] do
      scope "/dashboard/admin" do
        # RBAC managed in Voile
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
    get "/:username/blogs", ProfileController, :blogs
    get "/:username/blogs/:slug", ProfileController, :show_blog
    get "/:username/posts", ProfileController, :posts
    get "/:username/posts/:id", ProfileController, :show_posts
    get "/:username/works", ProfileController, :works
    get "/:username/works/:id", ProfileController, :show_works
  end
end
