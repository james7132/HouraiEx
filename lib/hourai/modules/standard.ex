defmodule Hourai.Commands.Standard do

  use Hourai.CommandModule

  alias Hourai.CommandParser
  alias Hourai.Constants
  alias Hourai.Permissions
  alias Hourai.Precondition
  alias Hourai.Util
  alias Nostrum.Cache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member

  submodule Hourai.Commands.Standard.Hash
  submodule Hourai.Commands.Standard.Server

  command "echo", do: reply(context, Enum.join(context.args, " "))

  command "whois" do
    case Cache.Guild.GuildServer.get(channel_id: context.msg.channel_id) do
      {:ok, guild} -> whois_guild_member(context, guild)
      _ -> whois_generic(context)
    end
  end

  defp whois_guild_member(context,  %Guild{} = guild) do
    user = Util.get_default_target_user(context, guild.members)
    with {:ok, guild_member} <- Util.get_guild_member(user.id, guild) do
      roles = Util.get_roles(guild, guild_member.roles)
              |> Enum.reject(&String.contains?(&1.name, "everyone"))
      response =
        ["""
         Username: `#{Util.id_string(user)}`
         Nickname: `#{guild_member.nick || "N/A"}`
         Created on: `#{user.id |> Util.created_on |> DateTime.to_string}`
         Joined on: `#{get_joined_at_date(guild_member)}`
         """,
         case roles do
           nil -> nil
           role_list -> "Roles: #{Util.codify_list(role_list, fn r -> r.name end)}"
         end,
         Constants.get_avatar_url(user)]
         |> join_truthy("\n")
       reply(context, response)
    end
  end

  defp whois_generic(context) do
    user = Util.get_default_target_user(context, [])
    reply(context,
    """
    Username: `#{Util.id_string(user)}`
    Created on: `#{user.id |> Util.created_on |> DateTime.to_string}`
    #{Constants.get_avatar_url(user)}
    """)
  end

  defp get_joined_at_date(%Member{joined_at: join_date}) do
    case join_date do
      nil -> "N/A"
      _ ->
        {:ok, date, _} = DateTime.from_iso8601(join_date)
        DateTime.to_string(date)
    end
  end

  defp join_truthy(enum, seperator) do
    enum
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn x -> x end)
    |> Enum.join(seperator)
  end

  command "avatar" do
    response =
      context.args
      |> Enum.map(&CommandParser.parse_user/1)
      |> Enum.map(&Constants.get_avatar_url(&1))
      |> join_truthy("\n")
    reply(context, response)
  end

  command "choose", do: reply(context, "I choose #{Enum.random(context.args)}!")

  command "invite", do: reply(context,
    "Use this link to add me to your server: https://discordapp.com/oauth2/authorize?client_id=208460637368614913&scope=bot&permissions=0xFFFFFFFFFFFF")

end

defmodule Hourai.Commands.Standard.Hash do

  use Hourai.CommandModule

  @prefix "hash"

  command "md5", do: hash(context, :md5)
  command "sha128", do: hash(context, :sha)
  command "sha256", do: hash(context, :sha256)
  command "sha512", do: hash(context, :sha512)

  defp hash(context, hash_alg) do
    response =
      context.args
      |> Enum.join(" ")
      |> (&:crypto.hash(hash_alg, &1)).()
      |> Base.encode16(case: :lower)
    reply(context, response)
  end

end

defmodule Hourai.Commands.Standard.Server do

  use Hourai.CommandModule

  alias Hourai.Constants
  alias Hourai.Permissions
  alias Hourai.Precondition
  alias Hourai.Util
  alias Nostrum.Cache.UserCache

  @prefix "server"

  def module_preconditions(context) do
    Precondition.in_guild(context)
  end

  command "permissions" do
    user = Util.get_default_target_user(context.msg)
    with {:ok, member} <- Util.get_guild_member(user.id, context.guild) do
      context.guild
      |> Util.get_guild_permission(member.roles)
      |> Permissions.get_permissions()
      |> Util.codify_list(&Permissions.to_string/1)
      |> Util.reply(context.msg)
    end
  end

  command "info" do
    with {:ok, guild} <- Precondition.in_guild(context.msg),
         {:ok, owner} <- UserCache.get(id: guild.owner_id) do
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
      reply(context, response)
    end
  end

end
