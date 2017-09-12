defmodule Hourai.Schema.Discord.Feed do
  use Ecto.Schema

  schema "discord_feed" do
    field :feed_url, :string
    has_many :channels, Hourai.Discord.FeedChannel

    timestamps
  end

end
