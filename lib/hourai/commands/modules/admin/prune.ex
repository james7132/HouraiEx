defmodule Hourai.Commands.Admin.Prune do

  use Hourai.CommandModule

  alias Hourai.AdminUtil
  alias Hourai.Precondition
  alias Hourai.Util
  alias Nostrum.Api
  alias Nostrum.Cache.Guild.GuildServer
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild.Member

  @prefix "prune"

  def module_preconditions(context) do
    Precondition.in_guild(context)
  end

  def command_preconditions(context, {_, opts}) do
    context = Map.merge(context, %{me: Util.me(), author: context.msg.author})
    check = Keyword.get(opts, :check)
    with %{} = context <- Precondition.has_guild_permission(context, :me, :manage_messages) do
      if check != nil and check do
        with %{} = context <- Precondition.has_guild_permission(context, :author, :manage_messages) do
          context
        end
      else
        context
      end
    end
  end

  command("default", default: true) do
    messages(context)
    |> execute()
  end

  command "embed", do:
    messages(context)
    |> filter(fn msg -> Enum.any?(msg.attachments) || Enum.any?(msg.embeds) end)
    |> execute

  command("mine", check: false) do
    id = context.msg.author.id
    messages(context)
    |> filter(&(&1.author.id == id))
    |> execute()
  end

  command "bot", do:
    messages(context)
    |> filter(fn msg -> Map.get(msg.author, :bot) end)
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
    channel_id = context.msg.channel_id
    ids = Enum.map(messages, &(&1.id))
    cond do
      !Enum.at(messages, 0) -> reply(context, "Successfully deleted 0 messages.")
      !Enum.at(messages, 1) ->
        for id <- ids, do: Api.delete_message(channel_id, id)
        reply(context, "Successfully deleted 1 message.")
      true ->
        {:ok } = Api.bulk_delete_messages(channel_id, ids)
        reply(context, "Successfully deleted #{count} messages")
    end
  end

end
