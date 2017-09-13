defmodule Hourai.Commands.Standard do

  alias Hourai.Constants
  alias Hourai.Permissions
  alias Hourai.Precondition
  alias Hourai.Util
  alias Nostrum.Cache

  def server_permissions(msg) do
    with {:ok, guild} <- Precondition.in_guild(msg) do
      user = Util.get_default_target_user(msg)
      with {:ok, member} <- Util.get_guild_member(user.id, guild) do
        guild
        |> Util.get_guild_permission(member.roles)
        |> Permissions.get_permissions
        |> Util.codify_list(fn perm ->
            perm
            |> Atom.to_string
            |> String.replace("_", " ")
            |> String.capitalize
          end)
        |> Util.reply(msg)
      end
    end
  end

  def serverinfo(msg) do
    with {:ok, guild} <- Precondition.in_guild(msg),
         {:ok, owner} <- Cache.UserCache.get(id: guild.owner_id) do
      response ="""
      \nName: `#{guild.name}`
      ID: `#{guild.id}`
      Owner: `#{Util.id_string(owner)}`
      Region: `#{guild.region}`
      Members: `#{guild.member_count}`
      """
      response =
        if Enum.any?(guild.roles),
        do: response <> "Roles: #{Util.guild_role_list(guild)}\n",
        else: response
      response =
        if Enum.any?(Enum.filter(guild.channels, fn c -> c.type != 0 end)),
        do: response <> "Text Channels: #{Util.guild_text_channel_list(guild)}\n",
        else: response
      response =
        if Enum.any?(Enum.filter(guild.channels, fn c -> c.type != 2  end)),
        do: response <> "Voice Channels: #{Util.guild_voice_channel_list(guild)}\n",
        else: response
      icon_url = Constants.guild_icon_url(guild)
      response = if icon_url, do: response <> icon_url, else: response
      Util.reply(response, msg)
    end
  end

  def whois(msg) do
    user = Util.get_default_target_user(msg)
    member =
      with {:ok, guild} <- Cache.Guild.GuildServer.get(channel_id: msg.channel_id),
           {:ok, guild_member} <- Util.get_guild_member(user.id, guild) do
         roles = Util.get_roles(guild, guild_member.roles)
                 |> Enum.reject(fn r -> String.contains?(r.name, "everyone") end)
         {:ok, guild_member, roles}
      end

    username = "Username: `#{Util.id_string(user)}`"
    created_on = "Created on: `#{user.id |> Util.created_on |> DateTime.to_string}`"
    avatar = Constants.get_avatar_url(user)
    case member do
      {:ok, guild_member, roles} ->
        [
          username,
          case Map.get(guild_member, :nick) do
            nil -> nil
            nick -> "Nickname: `#{nick}`"
          end,
          created_on,
          case Map.get(guild_member, :joined_at) do
            nil -> nil
            joined_at ->
              {:ok, join_date, _} = DateTime.from_iso8601(joined_at)
              "Joined on: `#{DateTime.to_string(join_date)}`"
          end,
          case roles do
            nil -> nil
            role_list -> "Roles: #{Util.codify_list(role_list, fn r -> r.name end)}"
          end,
          avatar
        ]
      {:error, _} -> [username, created_on, avatar]
    end
    |> Enum.filter(fn x -> x != nil end)
    |> Enum.join("\n")
    |> Util.reply(msg)
  end

  def avatar(msg) do
    msg.mentions
    |> Enum.map(&Constants.get_avatar_url(&1))
    |> Enum.filter(fn a -> a != nil end)
    |> Enum.join("\n")
    |> Util.reply(msg)
  end

  def choose(msg, options) do
    Util.reply("I choose #{Enum.random(options)}!", msg)
  end

  def echo(msg, options) do
    options
    |> Enum.join(" ")
    |> Util.reply(msg)
  end

  def invite(msg) do
    Util.reply("Use this link to add me to your server: https://discordapp.com/oauth2/authorize?client_id=208460637368614913&scope=bot&permissions=0xFFFFFFFFFFFF", msg)
  end

  def hash(msg, alg, options) do
    hash_alg =
      case alg do
        "md5" -> :md5
        "sha128" -> :sha
        "sha256" -> :sha256
        "sha512" -> :sha512
      end
    options
    |> Enum.join(" ")
    |> (&:crypto.hash(hash_alg, &1)).()
    |> Base.encode16(case: :lower)
    |> Util.reply(msg)
  end

end
