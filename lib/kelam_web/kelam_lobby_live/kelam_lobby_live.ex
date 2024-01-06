defmodule KelamWeb.KelamLobbyLive do
  require Logger
  use KelamWeb, :live_view
  alias KelamWeb.LobbyCache, as: Lobby
  # alias Kelam.PubSub

  @impl true
  def mount(%{"lobby_id" => lobby_id, "username" => username}, _session, socket) do
    topic = "lobby:" <> lobby_id
    Logger.info("Topic: " <> topic)

    if connected?(socket) do
      KelamWeb.Presence.track(self(), topic, username, %{})
      KelamWeb.Endpoint.subscribe(topic)
    end

    settings =
      if Lobby.check(topic) do
        Lobby.get(topic)
      else
        Lobby.put(topic, %{yt_captioning: false, yt_caption_url: "", seq: 0})
        Lobby.get(topic)
      end

    Logger.info(settings)

    {:ok,
     assign(socket,
       username: username,
       lobby_id: lobby_id,
       topic: topic,
       messages: [],
       user_list: [],
       settings: settings
     )}
  end

  @impl true
  def handle_event(
        "message",
        %{"message" => content, "start" => start, "end" => end_stamp},
        socket
      ) do
    message = %{
      id: Nanoid.generate(8),
      username: socket.assigns.username,
      content: content,
      start: start,
      end_stamp: end_stamp
    }

    KelamWeb.Endpoint.broadcast(socket.assigns.topic, "new_message", message)

    yt_post(
      %{
        username: socket.assigns.username,
        content: content,
        start: start,
        end_stamp: end_stamp
      },
      socket.assigns.topic
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("yt_toggle", %{}, socket) do
    yt_captioning_status = Lobby.get(socket.assigns.topic).yt_captioning

    if yt_captioning_status do
      Lobby.update(socket.assigns.topic, :yt_captioning, false)
    else
      Lobby.update(socket.assigns.topic, :yt_captioning, true)
    end

    KelamWeb.Endpoint.broadcast(
      socket.assigns.topic,
      "settings_changed",
      Lobby.get(socket.assigns.topic)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("yt_captions_url_changed", %{"yt_caption_url" => yt_caption_url}, socket) do
    Lobby.update(socket.assigns.topic, :yt_caption_url, yt_caption_url)

    KelamWeb.Endpoint.broadcast(
      socket.assigns.topic,
      "settings_changed",
      Lobby.get(socket.assigns.topic)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "settings_changed", payload: settings}, socket) do
    {:noreply, assign(socket, settings: settings)}
  end

  @impl true
  def handle_info(%{event: "new_message", payload: message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{}}, socket) do
    user_list =
      for user <- KelamWeb.Presence.list(socket.assigns.topic),
          do: %{username: elem(user, 0)}

    {:noreply,
     assign(socket,
       user_list: user_list
     )}
  end

  def yt_post(
        %{
          username: username,
          content: content,
          start: start,
          end_stamp: end_stamp
        },
        topic
      ) do
    lobby_settings = Lobby.get(topic)

    caption =
      "#{start}" <>
        "\n" <> "#{username}: #{content}" <> "\n" <> "#{end_stamp}" <> "\n" <> " " <> "\n"

    if lobby_settings.yt_captioning do
      temp_seq = Lobby.get(topic).seq
      Lobby.update(topic, :seq, temp_seq + 1)
      myurl = lobby_settings.yt_caption_url <> "&seq=" <> Integer.to_string(lobby_settings.seq)

      res =
        Req.post!(myurl,
          headers: [{"content-type", "text/plain"}],
          body: caption
        )

      Logger.info(res)
    end

    {:ok}
  end
end
