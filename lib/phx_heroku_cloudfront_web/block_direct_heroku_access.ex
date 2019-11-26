defmodule PhxHerokuCloudfrontWeb.Plugs.BlockDirectHerokuAccess do
  def init(default), do: default

  def call(%Plug.Conn{} = conn, _default) do
    if String.ends_with?(conn.host, ".herokuapp.com") do
      conn
      |> Plug.Conn.put_status(:moved_permanently)
      |> Phoenix.Controller.redirect(external: "https://" <> System.get_env("DOMAIN_NAME"))
      |> Plug.Conn.halt()
    else
      conn
    end
  end
end
