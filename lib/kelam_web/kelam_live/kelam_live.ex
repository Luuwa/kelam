defmodule KelamWeb.KelamLive do
  require Logger
  use KelamWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: " ", results: %{})}
  end

  @impl true
  def handle_event("create_lobby", _unsigned_params, socket) do
    lobby_id = "/" <> MnemonicSlugs.generate_slug(4)
    # Logger.info(lobby_id)
    {:noreply, push_navigate(socket, to: lobby_id)}
  end
end
