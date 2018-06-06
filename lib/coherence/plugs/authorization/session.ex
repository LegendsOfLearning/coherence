defmodule Coherence.Authentication.Session do
  @moduledoc """
  Implements Session based authentication. By default, it uses an Server for
  session state. Additionally, a the session can be stored in a database with
  an Server based cache.

  The plug can be used to force a login for unauthenticated users for routes
  that need to be protected with a password.

  For example:

      plug Coherence.Authentication.Session, protected: true

  will present the user for a login if they are accessing a route or controller
  that uses this plug.

  For pages that don't require authorization but would like to present logged in
  information on unprotected pages, use the default:

      plug Coherence.Authentication.Session

  This will set the current_user for use in templates, but not allow access to
  protected pages.

  By default, the user model for a logged-in user can be accessed with
  `Coherence.current_user(conn)` which is just a shortcut for
  `conn.assigns[:current_user]`. This can be changed with the global
  :assigns_key config option.

  ## Controller Based Authentication

  This plug can be used in either the router.ex file or in a controller file.

  ## Database Persistence

  To enable database persistence, implement [Coherence.DbStore] protocol for your
  user model. As well, you will need to provide the :db_model option to the plug. For
  example:

      defimpl Coherence.DbStore, for: MyProject.User do
        def get_user_data(_, creds, _id_key) do
          alias MyProject.{Session, Repo}
          case Repo.one from s in Session, where: s.creds == ^creds, preload: :user do
            %{user: user} -> user
            _ -> nil
          end
        end

        def put_credentials(user, creds , _) do
          case Repo.one from s in Session, where: s.creds == ^creds do
            nil -> %Session{creds: creds}
            session -> session
          end
          |> Session.changeset(%{user_id: user.id})
          |> Repo.insert_or_update
        end

        def delete_credentials(_, creds) do
          case Repo.one from s in Session, where: s.creds == ^creds do
            nil -> nil
            session ->
              Repo.delete session
          end
        end
      end

      plug Coherence.Authentication.Session, db_model: MyProject.User, protected: true

  You should be aware that the Server is still used to fetch the user data if can
  be found. If the key is not found, it checks the database. If a record is found
  in the database, the server is updated and the user data returned.


  This module is derived from https://github.com/lexmag/blaguth
  """

  @behaviour Plug

  import Plug.Conn
  import Coherence.Authentication.Utils

  alias Coherence.{Config}

  require Logger

  @type t :: Ecto.Schema.t | Map.t
  @type conn :: Plug.Conn.t

  @session_key Application.get_env(:coherence, :session_key, "session_auth")

  @dialyzer [
    {:nowarn_function, call: 2},
    {:nowarn_function, get_session_data: 1},
    {:nowarn_function, verify_rememberable: 2},
    {:nowarn_function, verify_auth_key: 3},
    {:nowarn_function, assert_login: 3},
    {:nowarn_function, init: 1},
  ]

  def login_user(conn, user, params \\ %{}) do
    conn
    |> create_login(user, params)
    |> Coherence.TrackableService.track_login(user, Config.user_schema.trackable?, Config.user_schema.trackable_table?)
  end

  @doc """
    Create a login for a user. `user_data` can be any term but must not be `nil`.
  """
  @spec create_login(conn, t, Keyword.t) :: conn
  def create_login(conn, user_data, opts  \\ []) do
    if is_nil(conn.assigns[:auth_session_plug_opts]) do
      Logger.warn "Coherence.Authentication.Session plug was not added to this pipeline.  Options provided in router will not be available"
    end
    opts = Keyword.merge(opts, Map.to_list(conn.assigns[:auth_session_plug_opts] || %{}))
    id_key = Keyword.get(opts, :id_key, :id)
    store = Keyword.get(opts, :store, Coherence.CredentialStore.Session)
    { gen_callback_mod, gen_callback_fn } = Keyword.get(opts, :generate_auth_session_id_callback, { Coherence.Authentication.Session, :generate_id_as_uuid })
    { conn, id } = apply(gen_callback_mod, gen_callback_fn, [ conn, user_data, opts ])

    store.put_credentials({id, user_data, id_key})

    { update_callback_mod, update_callback_fn } = Keyword.get(opts, :update_conn_callback, Config.update_conn_callback)

    apply(update_callback_mod, update_callback_fn, [conn, id])
    |> put_session(@session_key, id)
  end

  @doc """
    Update login store for a user. `user_data` can be any term but must not be `nil`.
  """
  @spec update_login(conn, t, Keyword.t) :: conn
  def update_login(conn, user_data, opts  \\ []) do
    id_key = Keyword.get(opts, :id_key, :id)
    store = Keyword.get(opts, :store, Coherence.CredentialStore.Session)
    id = get_session(conn, @session_key)

    { update_callback_mod, update_callback_fn } = Keyword.get(opts, :update_conn_callback, Config.update_conn_callback)

    store.put_credentials({id, user_data, id_key})
    apply(update_callback_mod, update_callback_fn, [conn, id])
  end

  @doc """
    Delete a login.
  """
  @spec delete_login(conn, Keyword.t) :: conn
  def delete_login(conn, opts \\ []) do
    store = Keyword.get(opts, :store, Coherence.CredentialStore.Session)
    case get_session(conn, @session_key) do
      nil ->
        conn
      key ->
        store.delete_credentials(key)

        conn
        |> clear_session()
    end
    |> delete_token_session
    |> delete_user_token
  end

  @spec update_conn(conn, String.t) :: conn
  def update_conn(conn, _id) do
    conn
  end

  # defp default_login_callback do
  #   module =
  #     :coherence
  #     |> Application.get_env(:module)
  #     |> Module.concat(Coherence.SessionController)

  #   Code.ensure_loaded module

  #   if function_exported?(module, :login_callback, 1) do
  #     &module.login_callback/1
  #   else
  #     &Coherence.SessionController.login_callback/1
  #   end
  # end

  @doc false
  @spec init(Keyword.t) :: [tuple]
  def init(opts) do
    login =
      case opts[:login] do
        true  -> true
        fun when is_function(fun) ->
          fun
        other ->
          case opts[:protected] do
            nil -> other
            true -> true
            other -> other
          end
      end

    rememberable? =
      if Config.has_option(:rememberable) do
        Config.user_schema.rememberable?
      else
        false
      end

    %{
      login: login,
      protected: opts[:protected] || false,
      new_session_params: opts[:new_session_params] || %{},
      authorize: Keyword.get(opts, :authorize),
      error: Keyword.get(opts, :error, "HTTP Authentication Required"),
      db_model: Keyword.get(opts, :db_model),
      id_key: Keyword.get(opts, :id, :id),
      store: Keyword.get(opts, :store, Coherence.CredentialStore.Session),
      assigns_key: Keyword.get(opts, :assigns_key, :current_user),
      login_key: Keyword.get(opts, :login_cookie, Config.login_cookie),
      rememberable: Keyword.get(opts, :rememberable, rememberable?),
      cookie_expire: Keyword.get(opts, :login_cookie_expire_hours, Config.rememberable_cookie_expire_hours) * 60 * 60,
      rememberable_callback: Keyword.get(opts, :rememberable_callback),
      generate_auth_session_id_callback: Keyword.get(opts, :generate_auth_session_id_callback, Config.generate_auth_session_id_callback),
      update_conn_callback: Keyword.get(opts, :update_conn_callback, Config.update_conn_callback)
    }
  end

  def generate_id_as_uuid(conn, _user_data, _opt) do
    { conn, UUID.uuid1 }
  end

  @doc false
  @spec call(conn, Keyword.t) :: conn
  def call(conn, opts) do
    conn = conn
      |> assign(:auth_session_plug_opts, opts)

    if user = get_authenticated_user(conn) do
      { conn, user }
      |> assert_authorize(opts[:authorize], opts)
    else
      conn
      |> get_session_data
      |> verify_auth_key(opts, opts[:store])
      |> verify_rememberable(opts)
      |> assert_login(opts[:login], opts)
      |> assert_authorize(opts[:authorize], opts)
    end
  end

  defp get_session_data(conn) do
    {conn, get_session(conn, @session_key)}
  end

  defp verify_rememberable({conn, nil}, %{rememberable: true, login_key: key} = opts)  do
    with cookie when not is_nil(cookie) <- conn.cookies[key],
         [id, series, token] <- String.split(cookie, " ") do
      case opts[:rememberable_callback] do
        nil ->
          Coherence.SessionController.rememberable_callback(conn, id, series, token, opts)
        fun ->
          fun.(conn, id, series, token, opts)
      end
    else
      _ -> {conn, nil}
    end
  end

  defp verify_rememberable(other, _opts), do: other

  defp verify_auth_key({conn, nil}, _, _), do: {conn, nil}
  defp verify_auth_key({conn, auth_key}, %{db_model: db_model, id_key: id_key}, store),
    do: {conn, store.get_user_data({auth_key, db_model, id_key})}

  defp assert_login({conn, no_userdata = nil}, login, opts) when login == true or is_function(login) do
    user_return_to =
      case conn.query_string do
        "" -> conn.request_path
        _ -> conn.request_path <> "?" <> conn.query_string
      end
    conn = put_session(conn, "user_return_to",  user_return_to)
    conn = if login == true do
      Phoenix.Controller.redirect conn, to: new_session_path(conn, opts[:new_session_params])
    else
      login.(conn)
    end
    { conn |> halt, no_userdata }
  end

  defp assert_login({conn, user_data}, _, opts) do
    assign_key = opts[:assigns_key]
    conn = conn
    |> assign_user_data(user_data, assign_key)
    |> create_user_token(user_data, Config.user_token, assign_key)
    { conn, user_data }
  end
  defp assert_login(conn, _, _) do
    { conn, nil }
  end

  defp assert_authorize({ %{ halted: true } = conn, _}, _, _) do
    conn
  end

  defp assert_authorize({conn, _user_data = nil}, _authorize_fn = nil, %{ protected: true } = opts) do
    conn
    |> redirect_to_require_signin(opts)
  end

  defp assert_authorize({conn, _user_data}, _authorize_fn = nil, _opts) do
    conn
  end

  defp assert_authorize({conn, user_data}, authorize_fn, opts) when is_function(authorize_fn) do
    case authorize_fn.({conn, user_data}, opts) do
      { conn, _authorized = true } -> conn
      { conn, _ } -> conn |> redirect_to_require_signin(opts)
    end
  end

  defp redirect_to_require_signin(conn, opts) do
    user_return_to =
    case conn.query_string do
      "" -> conn.request_path
      _ -> conn.request_path <> "?" <> conn.query_string
    end
    conn
    |> put_session("user_return_to",  user_return_to)
    |> Phoenix.Controller.put_flash(:error, "You are not authorized to perform this action.")
    |> Phoenix.Controller.redirect(to: new_session_path(conn, opts[:new_session_params]))
    |> halt
  end
end
