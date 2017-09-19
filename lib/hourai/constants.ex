defmodule Hourai.Constants do

  @cdn_url "https://cdn.discordapp.com/"

  def get_avatar_url(user, size \\ 1024) do
    if user.avatar do
      extension = get_avatar_extension(user.avatar)
      "#{@cdn_url}avatars/#{user.id}/#{user.avatar}.#{extension}?size=#{size}"
    end
  end

  defp get_avatar_extension(avatar_hash) do
    if String.starts_with?(avatar_hash, ["a_"]), do: "gif", else: "png"
  end

  def guild_icon_url(guild) do
    if guild.icon, do: "#{@cdn_url}icons/#{guild.id}/#{guild.icon}.jpg"
  end

end
