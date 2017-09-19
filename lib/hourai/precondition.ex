defmodule Hourai.Precondition do

  use Bitwise

  @owner_id 151215593553395721

  alias Hourai.Util
  alias Hourai.Permissions
  alias Nostrum.Cache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member

  def author_is_owner(context) do
    case context.msg.author.id do
      @owner_id -> context
      _ -> {:error, "Only the owner of the bot can use this command!"}
    end
  end

  def in_guild(context) do
    case Map.get(context, :guild) do
      nil ->
        case Cache.Guild.GuildServer.get(channel_id: context.msg.channel_id) do
          %Guild{} = guild -> %{context | guild: guild}
          {:error, _} -> {:error, "This command is only usable in a server!"}
        end
      %Guild{} -> context
    end
  end

  def has_guild_permission(context, user_key, permission) do
    guild = Map.get!(context, :guild)
    user = Map.get!(context, user_key)
    case Util.get_guild_member(user.id, guild) do
      {:ok, %Member{roles: roles}} ->
        perms = Util.get_guild_permission(guild, roles)
        if Permissions.has_permission(perms, permission) do
          {:ok, context}
        else
          perm_name = Permissions.to_string(permission)
          {:error, "#{user.username} does not have the `#{perm_name}` permission"}
        end
      _ -> {:error, "User not found."}
    end
  end

end
