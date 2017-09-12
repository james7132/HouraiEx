defmodule Hourai.Schema.Discord.Username do
  use Ecto.Schema

  schema "discord_username" do
    field :user_id, :integer, primary_key: true
    field :date, :utc_datetime, primary_key: true
    field :name, :string, size: 32
  end

end
