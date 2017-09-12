defmodule Hourai.Schema.Discord.FeedChannel do
  use Ecto.Schema

  schema "discord_feed" do
    field :channel_id, :integer
    belongs_to :feed, Hourai.Discord.Feed
  end

end
