defmodule Hourai.Util do

  use Bitwise

  alias Hourai.CommandParser
  alias Nostrum.Api
  alias Nostrum.Struct.Guild

  @max_size 2000

  def reply(content, msg) do
    Task.start fn ->
      channel_id = msg.channel_id
      if String.length(content) > @max_size do
        Api.create_message!(channel_id, content: "", file: content)
      else
        Api.create_message!(channel_id, content)
      end
    end
  end

  @doc"""
  Gets the full set of permissionns for a role set within a guild.
  Returns in integer form
  """
  def get_guild_permission(guild, roles) do
    # Bitwise OR all the permissions together
    Enum.reduce(get_roles(guild, roles), 0, fn(role, acc) ->
      acc ||| role.permissions
    end)
  end

  def get_roles(guild, roles) do
    role_set = roles |> Enum.into(%MapSet{})
    Enum.filter(guild.roles, &MapSet.member?(role_set, &1.id))
  end

  def get_guild_member(user_id ,guild) do
    case Enum.find(guild.members, :error, &(&1.user.id == user_id)) do
      :error -> {:error, "Guild member not found"}
      member -> {:ok, member}
    end
  end

  def get_default_target_user(msg, users \\ [], opts \\ []) do
    result = Enum.find_value(opts, &CommandParser.parse_user(&1, users))
    result || Enum.at(msg.mentions, 0) || msg.author
  end

  def me do
    Nostrum.Cache.Me.get()
  end

  def guild_role_list(%Guild{} = guild) do
    guild.roles
    |> Enum.drop(1)
    |> Enum.reverse
    |> codify_list(&(&1.name))
  end

  def guild_text_channel_list(guild) do
    guild_channel_list(guild, 0)
  end

  def guild_voice_channel_list(guild) do
    guild_channel_list(guild, 2)
  end

  defp guild_channel_list(guild, type) do
    guild.channels
    |> Enum.filter(&(&1.type == type))
    |> codify_list(&(&1.name))
  end

  def codify_list(list, str_fn \\ fn x -> x end, sep \\ ", ") do
    Enum.join(for elm <- list do "`#{str_fn.(elm)}`" end, sep)
  end

  def id_string(user) do
    "#{user.username}##{user.discriminator} (#{user.id})"
  end

  def mention(user) do
    "<@#{user.id}>"
  end

  def created_on(snowflake) do
    DateTime.from_unix!((snowflake >>> 22) + 1420070400000, :millisecond)
  end

end
