defmodule Hourai.CommandParser do

  alias Nostrum.Struct.Guild
  alias Nostrum.Cache.UserCache

  @id ~r/(?<id>\d+)/iu
  @regex_user_mention ~r/\<@(?<id>\d+)\>/iu
  @regex_nickname_mention ~r/\<@!(?<id>\d+)\>/iu
  @regex_channel_mention ~r/\<#(?<id>\d+)\>/iu
  @regex_role_mention ~r/\<@&(?<id>\d+)\>/iu

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
    search_fn =
      case get_id(role, [@regex_role_mention, @id]) do
        {:ok, id} -> fn r -> r.id == id end
        :error ->  fn r -> r.name == role end
      end
    case Enum.find(roles, search_fn) do
       nil -> :error
       role -> {:ok, role}
    end
  end

  def parse_channel(channel, %Guild{channels: channels}) when is_binary(channel) do
    search_fn =
      case get_id(channel, [@regex_channel_mention, @id]) do
        {:ok, id} -> fn c -> c.id == id end
        :error -> fn c -> c.name == channel end
      end
     case Enum.find(channels, search_fn) do
       nil -> :error
       role -> {:ok, role}
     end
  end

  def parse_guild_member(member, %Guild{members: members}) when is_binary(member) do
    search_fn =
      case get_id(member, [@regex_user_mention, @regex_nickname_mention, @id]) do
        {:ok , id} -> fn m -> m.user.id == id end
        :error -> fn m -> m.user.username == member or m.nick == member end
      end
    case Enum.find(members, search_fn) do
      nil -> :error
      member -> {:ok, member}
    end
  end

  def parse_user(user) when is_binary(user) do
    with {:ok, id} <- get_id(user, [@regex_user_mention, @regex_nickname_mention, @id]) do
       UserCache.get(id)
    end
  end

  defp get_id(target, regexes) do
    case Enum.find(regexes, &Regex.match?(&1, target)) do
      nil -> :error
      regex ->
         %{"id" => id_string} = Regex.named_captures(regex, target)
         {id, _} = Integer.parse(id_string)
         {:ok, id}
    end
  end

end
