defmodule Hourai.Commands.Admin do

  use Hourai.CommandModule

  alias Hourai.Precondition
  alias Hourai.CommandParser
  alias Hourai.Util
  alias Hourai.AdminUtil
  alias Nostrum.Api
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild.Member

  submodule Hourai.Commands.Admin.Prune

  def module_preconditions(context) do
    Precondition.in_guild(context)
  end

  def command_preconditions(context, {_, opts}) do
    context = Map.merge(context, %{me: Util.me(), author: context.msg.author})
    permission = Keyword.get(opts, :permission)
    if permission do
      with %{} = context <- Precondition.has_guild_permission(context, :me, permission),
           %{} = context <- Precondition.has_guild_permission(context, :author, permission) do
        context
      end
    else
      context
    end
  end

  command("kick", permission: :kick_members) do
    start(context, "kicked")
    |> parse_users()
    |> Map.put(:func,
       fn guild -> fn user ->
         Api.remove_member(guild.id, get_user_id(user))
        end end)
    |> run_command()
  end

  command("ban", permission: :ban_members) do
    start(context, "banned")
    |> parse_users()
    |> Map.put(:func,
        fn guild -> fn user ->
         IO.inspect {guild.id, get_user_id(user)}
         Api.create_guild_ban(get_user_id(user), guild.id, 0)
        end end)
    |> run_command()
  end

  command("softban", permission: :ban_members) do
    start(context, "softbanned")
    |> parse_users()
    |> Map.put(:func,
       fn guild -> fn user ->
         user_id = get_user_id(user)
         Api.create_guild_ban(guild.id, user_id, 7)
         Api.remove_guild_ban(guild.id, user_id)
        end end)
    |> run_command()
  end

  command("mute", permission: :mute_members) do
    start(context, "muted")
    |> parse_users()
    |> modify_users(%{mute: true})
    |> run_command()
  end

  command("unmute", permission: :mute_members) do
    start(context, "unmuted")
    |> parse_users()
    |> modify_users(%{mute: false})
    |> run_command
  end

  command("deafen", permission: :deafen_members) do
    start(context, "deafened")
    |> parse_users()
    |> modify_users(%{deaf: true})
    |> run_command()
  end

  command("undeafen", permission: :deafen_members) do
    start(context, "undeafened")
    |> parse_users()
    |> modify_users(%{deaf: false})
    |> run_command()
  end

  command("move", permission: :move_members) do
    src_channel = Enum.at(context.args, 0)
    dst_channel = Enum.at(context.args, 1)
    src = CommandParser.parse_channel(src_channel, context.guild)
    dst = CommandParser.parse_channel(dst_channel, context.guild)
    cond do
      !src -> reply(context, "Invalid channel: `#{src_channel}`")
      !dst -> reply(context, "Invalid channel: `#{dst_channel}`")
      true ->
        src_id = src.id
        users =
          context.guild.voice_states
          |> Enum.filter(&match?(%{channel_id: ^src_id}, &1))
          |> Enum.map(&(&1.user_id))
        start(context, "moved")
        |> Map.put(:users, users)
        |> modify_users(%{channel_id: dst.id})
        |> run_command()
    end
  end

  defp get_user_id(%Member{user: user}), do: get_user_id(user)
  defp get_user_id(%User{id: id}), do: id
  defp get_user_id(user), do: user

  defp start(context, action) do
    Map.put(context, :action, action)
  end

  defp parse_users(context) do
    Map.put(context, :users,  AdminUtil.get_users(context, context.guild))
  end

  defp modify_users(command_info, modify_opts) do
    Map.put(command_info, :func,
    fn guild -> fn user ->
        Api.modify_member(guild.id, get_user_id(user), modify_opts)
    end end)
  end

  defp run_command(context) do
    api_func = context.func.(context.guild)
    results =
      context.users
      |> api_action_per_user(api_func)
      |> parse_results(context.action, "user")
    reply(context, results)
  end

  defp parse_results({success, failures}, action, unit) do
    response = "Successfully #{action} #{success} #{unit}s."
    case failures do
      [] -> response
      errors -> response <> "\n\nErrors:\n  #{Enum.join(errors, "\n  ")}"
    end
  end

  defp api_action_per_user(users, action) do
    users
    |> Enum.map(&Task.async(fn -> action.(&1) end))
    |> Enum.reduce({0, []}, fn (task, {success, failures})->
      case Task.await(task) do
        {:ok} -> {success + 1, failures}
        {:error, %{message: message}} -> {success, [message["message"]] ++ failures}
      end
    end)
  end
end


defmodule Hourai.AdminUtil do

  alias Hourai.CommandParser
  alias Nostrum.Struct.Guild

  def get_users(context, guild \\ nil) do
    parser =
      case guild do
        %Guild{} -> &CommandParser.parse_guild_member(&1, guild)
        nil -> &CommandParser.parse_user/1
      end
    context.args
    |> Enum.map(parser)
    |> Enum.filter(fn x -> x end) # Filter non-matches
  end

end
