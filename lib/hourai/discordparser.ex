defmodule Hourai.CommandParser do

  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.User
  alias Nostrum.Cache.UserCache

  @id ~r/^(?<id>\d+)$/iu
  @regex_user_mention ~r/^\<@(?<id>\d+)\>$/iu
  @regex_nickname_mention ~r/^\<@!(?<id>\d+)\>$/iu
  @regex_channel_mention ~r/^\<#(?<id>\d+)\>$/iu
  @regex_role_mention ~r/^\<@&(?<id>\d+)\>$/iu

  def split(msg) when is_binary(msg) do
    {result, _} =
      msg
      |> String.split("\"")
      |> Enum.reduce({[], false},
        fn(opt, {opts, state}) ->
          if state do
            {[opt] ++ opts , false}
          else
            {(opt |> String.split |> Enum.reverse) ++ opts , true}
          end
        end)
    Enum.reverse(result)
  end

  def parse_role(role, %Guild{roles: roles}) when is_binary(role) do
    Enum.find_value(roles, search_fn(role, [@regex_role_mention, @id]))
  end

  def parse_channel(channel, %Guild{channels: channels}) when is_binary(channel) do
    Enum.find_value(channels, search_fn(channel, [@regex_channel_mention, @id]))
  end

  def parse_guild_member(member, %Guild{members: members}) when is_binary(member) do
    Enum.find_value(members,
                    search_fn(member, [@regex_user_mention, @regex_nickname_mention, @id]))
  end

  def parse_user(user, users \\ []) when is_binary(user) do
    case get_id(user, [@regex_user_mention, @regex_nickname_mention, @id]) do
      {:ok, id} ->
        Enum.find_value(users, &has_id(&1, id)) || UserCache.get(id)
      _ ->
        Enum.find_value(users, &has_name(&1, user))
    end
  end

  defp has_id(obj, id) do
    check =
      case obj do
        %Member{} = member -> if member.user.id == id, do: member
        _ -> if obj.id == id, do: obj
      end
    if check, do: obj
  end

  defp has_name(obj, name) do
    check =
      case obj do
        %User{} = user -> user.username == name
        %Member{} = member -> member.nick == name || has_name(member.user, name)
        _ -> obj.name == name
      end
    if check, do: obj
  end

  defp search_fn(name, regexes) do
    case get_id(name, regexes) do
      nil -> &has_name(&1, name)
      {:ok , id} -> &has_id(&1, id)
    end
  end

  defp get_id(opt, regexes) do
    with %{"id" => id_string} <- Enum.find_value(regexes, &Regex.named_captures(&1, opt)) do
      {id, _} = Integer.parse(id_string)
      {:ok, id}
    end
  end

end
