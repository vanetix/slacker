defmodule SlackerFrontendWeb.PageController do
  use SlackerFrontendWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
