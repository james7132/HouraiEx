defmodule Hourai.Schema.Discord.TempAction do
  use Ecto.Schema

  schema "discord_temp_action" do
    field :type, :integer
    field :user_id, :integer
    field :guild_id, :integer
    field :role_id, :integer
  end
end
