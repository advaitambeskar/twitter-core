defmodule ProjectWeb.LoginController do
  use ProjectWeb, :controller

  alias Project.Userdata
  alias Project.ClientFunctions

  def show(conn, _params) do
    IO.inspect(conn)
    changeset = Userdata.changeset(%Userdata{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"userdata" => user_params}) do
    user_data  = %Userdata{}
                 |> Userdata.changeset(user_params)

    if user_data.valid? do
      IO.puts("valid")
      %{"password" => password, "username" => username} = user_params
      response = ClientFunctions.register(username, password)
      IO.puts(response)
      if response == true do
        conn
        |> put_session(:current_user_name, username)
        |> put_flash(:info, "Signing in...")
        |> redirect(to: Routes.tweets_path(conn, :index))
        else
        render(conn, "new.html", changeset: user_data)
      end
      else
        IO.puts("error")
        IO.inspect(user_data)
        render(conn, "new.html", changeset: user_data)
    end
  end

  def logout(conn, _params) do
    IO.puts("HERE")
    username = Plug.Conn.get_session(conn, :current_user_name)
    ClientFunctions.logout(username)

    conn
    |> delete_session(:current_user_name)
    |> put_flash(:info, "Signed out successfully.")

    changeset = Userdata.changeset(%Userdata{})
    render(conn, "new.html", changeset: changeset)
  end

end
