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
      IO.puts permission
      with %{} = context <- Precondition.has_guild_permission(context, :me, permission),
           %{} = context <- Precondition.has_guild_permission(context, :author, permission) do
        context
      end
    else
      context
    end
  end

  command("kick", permission: :kick_members) do
    start(context, "muted")
    |> Map.put(:func,
       fn guild -> fn user ->
         Api.remove_member(guild.id, user.id)
        end end)
    |> run_command()
  end

  command("ban") do
    start(context, "banned")
    |> Map.put(:func,
        fn guild -> fn user ->
          Api.create_guild_ban(guild.id, get_user_id(user), 0)
        end end)
    |> run_command()
  end

  command("softban") do
    start(context, "softbanned")
    |> Map.put(:func,
       fn guild -> fn user ->
         user_id = get_user_id(user)
         Api.create_guild_ban(guild.id, user_id, 0)
         Api.remove_guild_ban(guild.id, user_id)
        end end)
    |> run_command()
  end

  # TODO(james7132): Figure a less ugly way to write this
  command("mute") do
    start(context, "muted")
    |> modify_users(%{mute: true})
    |> run_command()
  end

  command("unmute") do
    start(context, "unmuted")
    |> modify_users(%{mute: false})
    |> run_command
  end

  command("deafen")do
    start(context, "deafened")
    |> modify_users(%{deaf: true})
    |> run_command()
  end

  command("undeafen") do
    start(context, "undeafened")
    |> modify_users(%{deaf: false})
    |> run_command()
  end

  defp get_user_id(%Member{user: user}), do: get_user_id(user)
  defp get_user_id(%User{id: id}), do: id
  defp get_user_id(user), do: user

  defp start(context, action) do
    %{context | action: action}
  end

  defp modify_users(command_info, modify_opts) do
    Map.put(command_info, :func,
    fn guild -> fn user ->
        Api.modify_member(guild.id, get_user_id(user), modify_opts)
    end end)
  end

  defp run_command(command_info) do
    guild = command_info.guild
    api_func = command_info.func.(guild)
    results =
      AdminUtil.get_users(command_info.context, guild)
      |> api_action_per_user(api_func)
      |> parse_results(command_info.action, "user")
    reply(command_info.context, results)
  end

  defp parse_results({success, failures}, action, unit) do
    response = "Successfully #{action} #{success} #{unit}s."
    case failures do
      [] -> response
      errors -> response <> "Errors:\n  #{Enum.join(errors, "\n  ")}"
    end
  end

  defp api_action_per_user(users, action) do
    users
    |> Enum.map(&Task.async(fn -> action.(&1) end))
    |> Enum.reduce({0, []}, fn (task, {success, failures})->
      case Task.await(task) do
        {:ok} -> {success + 1, failures}
        error -> {success, [Exception.message(error)] ++ failures}
      end
    end)
  end
end

defmodule Hourai.Commands.Admin.Prune do

  use Hourai.CommandModule

  alias Hourai.AdminUtil
  alias Nostrum.Api
  alias Nostrum.Cache.Guild.GuildServer
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild.Member

  command "embed", do:
    messages(context)
    |> filter(fn msg -> Enum.any?(msg.attachements) || Enum.any?(msg.embeds) end)
    |> execute

  command "user" do
    users =
      context
      |> AdminUtil.get_users(GuildServer.get(channel_id: context.msg.channel_id))
      |> Enum.map(fn member ->
          case member do
            %Member{} -> member.user.id
            %User{} -> member.id
          end
        end)
      |> Enum.into(%MapSet{})
    messages(context)
    |> filter(fn msg -> MapSet.member?(users, msg.author.id) end)
    |> execute
  end

  defp messages(context, count \\ 100) do
    {:ok, messages} = Api.get_channel_messages(context.msg.channel_id, count)
    {context, count, messages}
  end

  defp filter({context, _, messages}, filter_fun) do
    {count, messages} =
      Enum.reduce(messages, {0, []}, fn (message, {count, msg_list}) ->
        if filter_fun.(message) do
          {count + 1, [message] ++ msg_list}
        else
          {count, msg_list}
        end
      end)
    {context, count, messages}
  end

  defp execute({context, count, messages}) do
    {:ok } = Api.bulk_delete_messages(context.msg.channel_id, messages)
    reply(context, "Successfully deleted #{count} messages")
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
