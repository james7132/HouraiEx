defmodule Hourai.Schema.Discord.CustomCommand do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "discord_custom_command" do
    field :guild_id, :integer, primary_key: true
    field :name, :string, primary_key: true
    field :response, :string, size: 2000
  end

  def changeset(command, params \\ %{}) do
    command
    |> cast(params, [:guild_id, :name, :response])
    |> validate_required([:guild_id, :name, :response])
  end
end
