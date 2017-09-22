defmodule Hourai.Reddit.Fetcher do

  use GenServer

  import Ecto.Query

  require Logger

  alias Hourai.Repo
  alias Hourai.Schema.Discord.{Feed, FeedChannel}
  alias Hourai.Reddit.Subreddit
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.{Author, Title}

  @refresh_time 0

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(state) do
    send(self(), :work)
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Feed type 1 is Reddit
    Repo.all(from feed in Feed,
             where: feed.type == 1,
             preload: :channels)
    |> Stream.filter(fn feed ->
        has_channels = Enum.any?(feed.channels)
        unless has_channels do
          Repo.delete(feed)
          Logger.info("Reddit feed '#{feed.descriptor}' has no more channels. Deleted.")
        end
        has_channels
       end)
    |> Stream.map(&({&1, Subreddit.new(&1.descriptor)}))
    |> Enum.each(&process_subreddit/1)

    Process.send_after(self(), :work, @refresh_time)
    {:noreply, state}
  end

  defp process_subreddit({feed, %{"data" => %{"children" => posts}}}) do
    valid_posts =
      posts
      |> Enum.map(&(&1["data"]))
      |> Enum.sort_by(&(&1["created_utc"]))
      |> Enum.filter(&(Timex.to_unix(feed.last_updated) <= &1["created_utc"]))

    IO.inspect length(valid_posts)

    if Enum.any?(valid_posts) do
      valid_posts
      |> Enum.map(&build_broadcast(feed, &1))
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(&elem(&1, 1))
      |> Enum.each(&broadcast_post(&1, feed))

      feed |> Feed.changeset(%{last_updated: Timex.now()}) |> Repo.update
    end
  end

  defp process_subreddit({feed, _}) do
    Logger.error("Malformed response for subreddit '#{feed.descriptor}'")
  end

  defp build_broadcast(feed, %{} = reddit_post) do
    content = "Post in /r/#{feed.descriptor}"
    description =
      if reddit_post["is_self"], do: reddit_post["selftext"], else: reddit_post["url"]
    author = reddit_post["author"]
    embed = %Embed{
      author: %Author{
        name: author,
        url: "https://reddit.com/u/#{author}"
      },
      description: description,
      title: reddit_post["title"],
      url: "https://reddit.com#{reddit_post["permalink"]}",
      timestamp:
        reddit_post["created_utc"]
        |> round()
        |> Timex.from_unix()
        |> Timex.format!("{ISO:Extended:Z}")
    }
    {:ok, [content: content, embed: embed]}
  end

  defp build_broadcast(feed, _) do
    error = "Malformed response for subreddit '#{feed.descriptor}'"
    Logger.error(error)
    {:error, error}
  end

  defp broadcast_post(content, feed) do
    Enum.each(feed.channels, &create_post(content, &1))
  end

  defp create_post(content, channel) do
    Task.start fn ->
      result = Nostrum.Api.create_message(channel.channel_id, content)
      with {:error, %{status_code: status}} <- result do
        case status do
          404 -> delete_feed_channel(channel)
          _ -> :noop
        end
      end
    end
  end

  defp delete_feed_channel(channel) do
      Logger.warn("Feed channel #{channel.channel_id} could not be found during a broadcast. Removing...")
      {:ok, _} = Repo.delete(channel)
  end

end
