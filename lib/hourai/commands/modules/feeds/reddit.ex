defmodule Hourai.Commands.Feeds.Reddit do

  use Hourai.CommandModule

  import Ecto.Query

  alias Hourai.{Repo, Precondition, Util}
  alias Hourai.Schema.Discord.{Feed, FeedChannel}

  @prefix "reddit"

  def module_preconditions(context) do
    Precondition.in_guild(context)
  end

  def command_precondition(context, {func, _}) do
    context = Map.put(context, :author,  context.msg.author)
    if func == :list do
      Precondition.has_guild_permission(context, :author, :manage_guild)
    else
      context
    end
  end

  command "add" do
    channel_id = context.msg.channel_id
    subreddit = get_subreddit_name(context)
    #TODO(james7132): Validate that the subreddit actually exists.
    {feed, channel} = get_feed_info(subreddit, context)
    feed = feed || make_feed(subreddit)
    if channel do
      reply(context, "Feed for subreddit '#{subreddit}' already exists.")
    else
        %FeedChannel{}
        |> FeedChannel.changeset(%{
          feed_id: feed.id,
          channel_id: channel_id
        })
        |> Repo.insert
        reply(context, "Feed for subreddit '#{subreddit}' added to <##{channel_id}>")
    end
  end

  command "remove" do
    channel_id = context.msg.channel_id
    subreddit = get_subreddit_name(context)
    {feed, channel} = get_feed_info(subreddit, context)
    if feed && channel do
      case Repo.delete(channel) do
        {:ok, _} ->
          reply(context, "Feed for subreddit '#{subreddit}' removed from <##{channel_id}>.")
        {:error, error} ->
          reply(context, "Something went wrong: #{error}")
      end
    else
      reply(context, "Feed for subreddit '#{subreddit}' does not exist.")
    end
  end

  command "list" do
    channel_id = context.msg.channel_id
    # Reddit feeds are of type 1
    results =
      Repo.all(
        from channel in FeedChannel,
         join: feed in Feed, on: feed.id == channel.feed_id,
         where: channel.channel_id == ^channel_id and feed.type == 1,
         select: feed.descriptor
      )
    if Enum.any?(results) do
      reply(context,
            results
            |> Enum.sort()
            |> Enum.map(&String.downcase/1)
            |> Util.codify_list())
    else
      reply(context, "There are no reddit feeds for this channel.")
    end
  end

  defp get_feed_info(subreddit, context) do
    channel_id = context.msg.channel_id
    feed = Repo.get_by(Feed, type: :reddit, descriptor: subreddit)
    channel =
      if feed do
        Repo.get_by(FeedChannel, feed_id: feed.id, channel_id: channel_id)
      end
    {feed, channel}
  end

  defp make_feed(subreddit) do
    {:ok, feed} =
      %Feed{}
      |> Feed.changeset(%{
        type: :reddit,
        descriptor: subreddit
      })
      |> Repo.insert
    feed
  end

  defp get_subreddit_name(context) do
    case Enum.at(context.args, 0) do
      nil -> nil
      subreddit_name -> String.downcase(subreddit_name)
    end
  end

end
