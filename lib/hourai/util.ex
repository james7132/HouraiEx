defmodule Hourai.Util do

  use Bitwise

  alias Hourai.CommandParser
  alias Nostrum.Api

  def reply(content, msg) do
    Task.async fn ->
      Api.create_message(msg.channel_id, content)
    end
  end

  @doc"""

  Gets the full set of permissionns for a role set within a guild.
  Returns in integer form

  """
  def get_guild_permission(guild, roles) do
    get_roles(guild, roles)
    |> Enum.reduce(0, fn(r, acc) -> acc ||| r.permissions end)
  end

  def get_roles(guild, roles) do
    role_set = roles |> Enum.into(%MapSet{})
    guild.roles
    |> Enum.filter(&MapSet.member?(role_set, &1.id))
  end

  def get_guild_member(user_id ,guild) do
    case Enum.find(guild.members, :error, &(&1.user.id == user_id)) do
      :error -> {:error, "Guild member not found"}
      member -> {:ok, member}
    end
  end

  def get_default_target_user(msg, users \\ [], opts \\ []) do
    result =
      opts
      |> Stream.map(&CommandParser.parse_user(&1, users))
      |> Enum.find(&match?({:ok, _}, &1))
    case result do
      nil ->
        case Enum.at(msg.mentions, 0) do
          nil -> msg.author
          user -> user
        end
      {:ok, user} -> user
    end
  end

  def me do
    Nostrum.Cache.Me.get()
  end

  def guild_role_list(guild, role_ids \\ []) do
    case role_ids do
      [] -> guild.roles
      role_list -> get_roles(guild, role_list)
    end
    |> Enum.drop(1)
    |> Enum.reverse
    |> codify_list(fn r -> r.name end)
  end

  def guild_text_channel_list(guild) do
    guild_channel_list(guild, 0)
  end

  def guild_voice_channel_list(guild) do
    guild_channel_list(guild, 2)
  end

  defp guild_channel_list(guild, type) do
    guild.channels
    |> Enum.filter(fn c -> c.type == type end)
    |> codify_list(fn c -> c.name end)
  end

  def codify_list(list, str_fn \\ fn x -> x end, sep \\ ", ") do
    list
    |> Enum.map(fn val -> "`#{str_fn.(val)}`" end)
    |> Enum.join(sep)
  end

  def id_string(user) do
    "#{user.username}##{user.discriminator} (#{user.id})"
  end

  def mention(user) do
    "<@#{user.id}>"
  end

  def created_on(snowflake) do
    snowflake >>> 22
    |> Kernel.+(1420070400000)
    |> DateTime.from_unix!(:millisecond)
  end

end
