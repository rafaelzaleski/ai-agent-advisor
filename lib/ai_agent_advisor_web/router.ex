defmodule AiAgentAdvisorWeb.Router do
  use AiAgentAdvisorWeb, :router

  import AiAgentAdvisorWeb.AuthPlug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AiAgentAdvisorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AiAgentAdvisorWeb do
    pipe_through :browser

    get "/", PageController, :home

    # OAuth Routes
    get "/auth/google", AuthController, :request, as: :google_auth
    get "/auth/hubspot", AuthController, :request, as: :hubspot_auth
    get "/auth/:provider/callback", AuthController, :callback
    get "/auth/logout", AuthController, :logout
  end

  scope "/", AiAgentAdvisorWeb do
    pipe_through [:browser, :require_auth]

    live "/settings", SettingsLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AiAgentAdvisorWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ai_agent_advisor, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AiAgentAdvisorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
