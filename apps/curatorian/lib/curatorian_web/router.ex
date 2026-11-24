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
    plug CuratorianWeb.Plugs.CSP
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

  # CSP violation reports: browsers POST these without any CSRF token by
  # design, so this endpoint must bypass protect_from_forgery. The body is
  # only logged, and the report-uri is set by our own CSP plug.
  pipeline :csp_report do
    plug :accepts, ["json", "csp-report"]
    plug :fetch_session
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
    get "/roadmap", PageController, :roadmap
    get "/privacy-policy", PageController, :privacy_policy
    get "/library/classification", PageController, :library_classification
    get "/sitemap.xml", SitemapController, :show
  end

  # CSP violation reports — outside the :browser pipeline so :protect_from_forgery
  # does not reject the browser's tokenless POSTs (the 403 noise in the logs).
  scope "/", CuratorianWeb do
    pipe_through :csp_report

    post "/csp-report", CspReportController, :report
  end

  # Session controller handles form POST from login/register LiveViews
  scope "/", CuratorianWeb do
    pipe_through :browser

    post "/login", UserSessionController, :create
    # DELETE is used by same-app logout links. GET renders a small
    # auto-submitting logout form for cross-app redirect-based logout
    # (e.g. Atrium redirecting here after clearing its own session) — this
    # keeps logout a POST with CSRF protection, never a GET state change.
    delete "/logout", UserSessionController, :delete
    get "/logout", LogoutConfirmController, :confirm

    # OAuth callbacks
    get "/auth/google", GoogleAuthController, :request
    get "/auth/google/callback", GoogleAuthController, :callback
  end

  # Auth LiveViews — mounts scope but does NOT require authentication.
  # Logged-in users are redirected away inside mount/3.
  scope "/", CuratorianWeb do
    pipe_through :browser

    live_session :unauthenticated_only,
      on_mount: [
        {CuratorianWeb.UserAuth, :mount_current_scope},
        {CuratorianWeb.Utils.SaveRequestUri, :on_mount}
      ] do
      live "/login", UserLoginLive, :new
      live "/register", UserRegistrationLive, :new
      live "/users/pending_confirmation", UserPendingConfirmationLive, :new
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
      live "/r/:token", Public.ParticipantPageLive, :show
    end
  end

  # ---------------------------------------------------------------------------
  # Public explore routes — no auth required, current_scope is still mounted
  # ---------------------------------------------------------------------------

  scope "/", CuratorianWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [
        {CuratorianWeb.UserAuth, :mount_current_scope},
        {CuratorianWeb.Utils.SaveRequestUri, :on_mount}
      ] do
      live "/kurator", Public.ProfilesLive, :index
      live "/u/:username", Public.ProfileShowLive, :show
      live "/u/:username/blog/:slug", Public.BlogShowLive, :show
      live "/blog", Public.CuratorsBlogLive, :index
      live "/orgs", Public.OrganizationsLive, :index
      live "/orgs/:slug", Public.OrganizationShowLive, :show
      live "/collections", Public.CollectionsLive, :index
      live "/collections/:id", Public.CollectionShowLive, :show
      live "/collections/:id/read/:attachment_id", Public.EbookReaderLive, :show

      # Session-gated byte streaming for the reader (no direct file URL).
      # GET + Accept header checks in the controller; :browser pipeline is
      # needed so the session cookie identifies the user.
      get "/ebooks/:id/stream", EbookStreamController, :stream

      live "/jobs", Public.Jobs.IndexLive, :index
      live "/jobs/:slug", Public.Jobs.ShowLive, :show
      live "/events", Public.Events.IndexLive, :index
      live "/events/:slug", Public.Events.ShowLive, :show
      # Guest registration lives in :public — the wizard collects a guest
      # identity (name/email) instead of requiring an account, and login is
      # only offered as an option. scope is still mounted, so logged-in
      # users get the account-prefilled path.
      live "/events/:slug/register", Public.Events.RegisterLive, :new
      live "/certificates/:id", Public.Events.CertificateLive, :show
      live "/certificates/verify/:token", Public.Events.CertificateLive, :verify
      live "/crowdfunding", Public.Crowdfunding.IndexLive, :index
      live "/crowdfunding/:slug", Public.Crowdfunding.ShowLive, :show
      live "/exchange", Public.CollectionExchange.IndexLive, :index
      live "/tools", Public.Tools.IndexLive, :index
      live "/tools/library", Public.Tools.Library.IndexLive, :index
      live "/tools/gallery", Public.Tools.Gallery.IndexLive, :index
      live "/tools/museum", Public.Tools.Museum.IndexLive, :index
      live "/tools/archive", Public.Tools.Archive.IndexLive, :index
      live "/tools/library/classifications", Public.Tools.Library.Classification.IndexLive, :index
      live "/guides", Public.GuidesLive, :index
      live "/guides/:slug", Public.GuideShowLive, :show
    end
  end

  # ---------------------------------------------------------------------------
  # Authenticated routes — require a logged-in user
  # ---------------------------------------------------------------------------

  scope "/", CuratorianWeb do
    pipe_through :browser

    live_session :authenticated,
      on_mount: [
        {CuratorianWeb.UserAuth, :require_authenticated},
        {CuratorianWeb.Utils.SaveRequestUri, :on_mount}
      ] do
      live "/jobs/my-applications", Public.Jobs.MyApplicationsLive, :index
      live "/jobs/:slug/apply", Public.Jobs.ApplyLive, :apply
      live "/foyer", Foyer.FoyerLive, :index
      live "/me/certificates", Public.CertificateWalletLive, :index
      live "/visitor/check-in", Visitor.CheckInLive, :index
      live "/visitor/check-out", Visitor.CheckOutLive, :index
      live "/personal/borrow-reviews", PersonalLibrary.BorrowRequestsLive, :index
    end
  end

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
