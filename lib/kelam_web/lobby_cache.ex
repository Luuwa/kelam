defmodule KelamWeb.LobbyCache do
  @kelam_cache :kelam_lobby
  def get(key) do
    Cachex.get!(@kelam_cache, key)
  end

  def check(key) do
    if get(key) do
      true
    else
      false
    end
  end

  def update(key, diff_key, diff_value) do
    temp_data = get(key)
    put(key, Map.put(temp_data, diff_key, diff_value))
  end

  def put(key, data) do
    Cachex.put(@kelam_cache, key, data)
    Cachex.expire(@kelam_cache, key, :timer.hours(12))
  end
end
