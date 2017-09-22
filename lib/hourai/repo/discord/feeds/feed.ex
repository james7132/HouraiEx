defmodule Hourai.Schema.Discord.Feed do
  use Ecto.Schema

  import Ecto.Changeset

  schema "discord_feed" do
    field :type, FeedType
    field :descriptor, :string
    field :last_updated, Timex.Ecto.DateTime

    has_many :channels, Hourai.Schema.Discord.FeedChannel
  end

  def changeset(feed, params \\ %{}) do
    feed
    |> cast(params, [:type, :descriptor, :last_updated])
    |> put_change(:last_updated, Timex.now())
    |> validate_required([:type, :descriptor, :last_updated])
  end

end
