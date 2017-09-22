defmodule Hourai.Schema.Discord.FeedChannel do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  schema "discord_feed_channel" do
    belongs_to :feed, Hourai.Schema.Discord.Feed, primary_key: true
    field :channel_id, :integer
  end

  def changeset(channel, params \\ %{}) do
    channel
    |> cast(params, [:feed_id, :channel_id])
    |> validate_required([:feed_id, :channel_id])
    |> foreign_key_constraint(:feed_id)
  end

end
