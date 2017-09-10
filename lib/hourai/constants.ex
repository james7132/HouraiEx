defmodule Hourai.Constants do

  @cdn_url "https://cdn.discordapp.com/"

  def get_avatar_url(user_id, avatar_id, size \\ 1024) do
    extension = if String.starts_with?(avatar_id, ["a_"]), do: "gif", else: "png"
    "#{@cdn_url}avatars/#{user_id}/#{avatar_id}.#{extension}?size=#{size}"
  end

  def guild_icon_url(guild) do
    if guild.icon, do: "#{@cdn_url}icons/#{guild.id}/#{guild.icon}.jpg", else: nil
  end

end
