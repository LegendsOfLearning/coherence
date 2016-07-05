defmodule TestCoherence.Router do
  use Phoenix.Router
  use Coherence.Router

  def login_callback(conn) do
    Phoenix.Controller.html(conn, "Login callback rendered")
    |> Plug.Conn.halt
  end

  pipeline :browser do
    plug :accepts, ["html", "text"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Database, db_model: TestCoherence.User, rememberable: true, login: &__MODULE__.login_callback/1
  end

  pipeline :public do
    plug :accepts, ["html", "text"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Database, db_model: TestCoherence.User, login: false
  end

  # not sure if we will use this
  # pipeline :rememberable do
  #   plug :accepts, ["html"]
  #   plug :fetch_session
  #   plug :fetch_flash
  #   plug :protect_from_forgery
  #   plug :put_secure_browser_headers
  #   plug Coherence.Authentication.Database, db_model: TestCoherence.User, rememberable: true
  # end

  scope "/" do
    pipe_through :browser
    coherence_routes :private

    get "/dummies/new", TestCoherence.DummyController, :new
  end
  scope "/" do
    pipe_through :public
    coherence_routes :public

    get "/dummies", TestCoherence.DummyController, :index
  end
end

