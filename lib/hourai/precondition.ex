defmodule Hourai.Precondition do

  use Bitwise

  @owner_id 151215593553395721

  alias Hourai.Util
  alias Hourai.Permissions
  alias Nostrum.Cache

  def author_is_owner(msg) do
    case msg.author.id do
      @owner_id ->
        :ok
      _ ->
        Util.reply("Only the owner of the bot can use this command!", msg)
        :error
    end
  end

  def in_guild(msg) do
    with {:error, reason} <- Cache.Guild.GuildServer.get(channel_id: msg.channel_id) do
      Util.reply("This command is only usable in a server!", msg)
      {:error, reason}
    end
  end

  def has_guild_permission(msg, user, permission) do
    with {:ok, guild} <- in_guild(msg),
         {:ok, member} <- Util.get_guild_member(user.id, guild) do
      perms = Util.get_guild_permission(guild, member.roles)
      IO.inspect {perms, Permissions.has_permission(perms, permission)}
      cond do
        Permissions.has_permission(perms, permission) -> {:ok, guild, member}
        true ->
          perm_name = permission
                      |> Atom.to_string
                      |> String.replace("_", " ")
                      |> String.capitalize
          Util.reply("#{user.username} does not have the `#{perm_name}` permission", msg)
          {:error, "User does not have the #{Atom.to_string(permission)} permission"}
      end
    end
  end

end
